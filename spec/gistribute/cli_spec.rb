# frozen_string_literal: true

require "spec_helper"

require "fileutils"

describe Gistribute::CLI do
  before do
    FileUtils.rm_rf TEMP
    FileUtils.mkdir_p TEMP
    suppress_stdout
  end

  after { FileUtils.rm_rf TEMP }

  let :version do
    File.read(File.expand_path("../VERSION", __dir__)).strip
  end

  describe "#initialize" do
    context "when no argument is provided" do
      args_should_trigger_help_screen
    end

    context "when there are too many args" do
      args_should_trigger_help_screen "too", "many"
    end
  end

  describe "#run" do
    context "when user inputs `y` at the installation prompt" do
      before { allow($stdin).to receive(:gets).and_return "y" }

      {
        "public single file": PUB_SINGLE_FILE_ID,
        "secret single file": SEC_SINGLE_FILE_ID,
        "no title": NO_TITLE_ID,
        "no || spacing": NO_PIPE_SPACING_ID
      }.each do |description, id|
        context "when run with a #{description} Gist" do
          test_single_file id, TEMP
        end
      end

      context "when given a directory that doesn't exist" do
        before { run NON_EXISTENT_DIR_ID }

        let(:file_contents) { File.read "#{TEMP}/#{NEW_DIR_FILENAME}" }

        it "creates the directory" do
          expect(file_contents).to eq SINGLE_FILE_CONTENTS
        end
      end

      context "when run with a multi-file Gist" do
        before { run MULTI_FILE_ID }

        let(:file1_contents) { File.read "#{TEMP}/#{MULTI_FILENAMES[0]}" }
        let(:file2_contents) { File.read "#{TEMP}/#{MULTI_FILENAMES[1]}" }

        it "downloads the files into the correct locations" do
          [file1_contents, file2_contents].each_with_index do |result, i|
            file_number = i + 1
            expect(result).to eq "F#{file_number}L1\nF#{file_number}L2\n"
          end
        end
      end

      context "when given a file for the current working directory" do
        test_single_file CWD_ID, Dir.pwd
      end

      context "when given a file for the home directory" do
        test_single_file HOME_ID, Dir.home
      end

      context "when given a bad ID (404)" do
        before do
          %i[puts print].each { |p| allow($stderr).to receive p }
          run "bad", fail_on_exit: false
        end

        it "prints the error to STDERR" do
          expect($stderr).to have_received(:print).with <<~EOS.chop.red
            \rThere was an error downloading the requested Gist.
            The error is as follows:
          EOS

          expect($stderr).to have_received(:puts).with(" 404 Not Found")
          expect($stderr).to have_received(:print).with("The ID that was queried is: ".red)
          expect($stderr).to have_received(:puts).with("bad")
        end
      end
    end

    context "when user inputs nothing at the installation prompt" do
      before do
        allow($stdin).to receive(:gets).and_return "\n"
        run PUB_SINGLE_FILE_ID
      end

      it "saves the file" do
        expect(File).to exist("#{TEMP}/#{FILENAME}")
      end
    end

    %w[n m].each do |ch|
      context "when user inputs `#{ch}` at the installation prompt" do
        before do
          allow($stdin).to receive(:gets).and_return ch
          run PUB_SINGLE_FILE_ID
        end

        it "doesn't save the file" do
          expect(File).not_to exist("#{TEMP}/#{FILENAME}")
        end
      end
    end

    context "when ran with the --yes flag" do
      before { run "--yes", PUB_SINGLE_FILE_ID }

      let(:file_contents) { File.read "#{TEMP}/#{FILENAME}" }

      it "downloads the file without prompting" do
        expect(file_contents).to eq SINGLE_FILE_CONTENTS
      end
    end
  end
end

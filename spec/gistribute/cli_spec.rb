# frozen_string_literal: true

require "spec_helper"

require "fileutils"

describe Gistribute::CLI do
  before do
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
    {
      "public single file": PUB_SINGLE_FILE_ID,
      "secret single file": SEC_SINGLE_FILE_ID,
      "no title": NO_TITLE_ID,
      "no || spacing": NO_PIPE_SPACING_ID
    }.each do |description, id|
      context "when run with a #{description} Gist" do
        before { run id }

        let(:file_contents) { File.read "#{TEMP}/#{FILENAME}" }

        it "downloads the file into #{TEMP}" do
          expect(file_contents).to eq SINGLE_FILE_CONTENTS
        end
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
      before { run CWD_ID }
      after { FileUtils.rm "#{Dir.pwd}/#{FILENAME}" }

      let(:file_contents) { File.read "#{Dir.pwd}/#{FILENAME}" }

      it "downloads the file into the current working directory" do
        expect(file_contents).to eq SINGLE_FILE_CONTENTS
      end
    end

    context "when given a file for the home directory" do
      before { run HOME_ID }
      after { FileUtils.rm "#{Dir.home}/#{FILENAME}" }

      let(:file_contents) { File.read "#{Dir.home}/#{FILENAME}" }

      it "downloads the file into the home directory" do
        expect(file_contents).to eq SINGLE_FILE_CONTENTS
      end
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
end

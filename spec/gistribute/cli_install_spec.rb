# frozen_string_literal: true

require "spec_helper"

TEMP = "/tmp/gistribute_spec"
FILENAME = "test.file"
NEW_DIR_FILENAME = "nested/test.file"
MULTI_FILENAMES = ["file1", "dir/file2"].freeze

SINGLE_FILE_CONTENTS = "Line 1\nLine 2\n"

# Test Gists
PUB_SINGLE_FILE_ID = "4346763"
SEC_SINGLE_FILE_ID = "5fa3c6bab88036e95d62cadf15128ec3"
NO_TITLE_ID = "5865a130f9cf40acd9f0e85d15e601a7"
NO_PIPE_SPACING_ID = "5677679b0db25054521753e5d59bed3d"
NON_EXISTENT_DIR_ID = "8c86bf9cda921ebe7ad1bf0c46afb108"
MULTI_FILE_ID = "8d4a2a4c8fe0b1427fed39c939857a40"
CWD_ID = "3c7006e629fcc54262ef02a5b2204735"
HOME_ID = "acb6caa80886101a68c5c85e4c100ddb"

def test_single_file(id, path)
  before { run id }

  # TEMP already gets `rm -rf`ed in the `cli_spec.rb` #after
  unless path == TEMP
    after { FileUtils.rm "#{path}/#{FILENAME}" }
  end

  let(:file_contents) { File.read "#{path}/#{FILENAME}" }

  it "downloads the file into #{path}" do
    expect(file_contents).to eq SINGLE_FILE_CONTENTS
  end
end

describe Gistribute::CLI do
  before do
    FileUtils.rm_rf TEMP
    FileUtils.mkdir_p TEMP
    suppress_stdout
  end

  after { FileUtils.rm_rf TEMP }

  describe "#install" do
    context "when user inputs `y` at the installation prompt" do
      before { simulate_user_input "y\n" }

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
        simulate_user_input "\n"
        run PUB_SINGLE_FILE_ID
      end

      it "saves the file" do
        expect(File).to exist("#{TEMP}/#{FILENAME}")
      end
    end

    %w[n m].each do |ch|
      context "when user inputs `#{ch}` at the installation prompt" do
        before do
          simulate_user_input "#{ch}\n"
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

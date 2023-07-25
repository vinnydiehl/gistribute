# frozen_string_literal: true

require "spec_helper"

NEW_DIR_FILENAME = "nested/test.file"
MULTI_FILENAMES = ["file1", "dir/file2"].freeze

SINGLE_FILE_CONTENTS = "Line 1\nLine 2\n"

# Test Gists

GIST_IDS = {
  pub_single_file: "4346763",
  sec_single_file: "5fa3c6bab88036e95d62cadf15128ec3",
  no_title: "5865a130f9cf40acd9f0e85d15e601a7",
  no_pipe_spacing: "5677679b0db25054521753e5d59bed3d",
  non_existent_dir: "8c86bf9cda921ebe7ad1bf0c46afb108",
  multi_file: "8d4a2a4c8fe0b1427fed39c939857a40",
  cwd: "3c7006e629fcc54262ef02a5b2204735",
  home: "acb6caa80886101a68c5c85e4c100ddb",
  gist_description: "332d3f90378380a00614a088d9c179c5",
  no_gist_description: "b35c3fcf05af11b7efc1a5dbd11d23be"
}.freeze

def test_single_file(id, path)
  before { run "install", id }

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
        "public single file": GIST_IDS[:pub_single_file],
        "secret single file": GIST_IDS[:sec_single_file],
        "no title": GIST_IDS[:no_title],
        "no || spacing": GIST_IDS[:no_pipe_spacing]
      }.each do |description, id|
        context "when run with a #{description} Gist" do
          test_single_file id, TEMP
        end
      end

      context "when given a directory that doesn't exist" do
        before { run "install", GIST_IDS[:non_existent_dir] }

        let(:file_contents) { File.read "#{TEMP}/#{NEW_DIR_FILENAME}" }

        it "creates the directory" do
          expect(file_contents).to eq SINGLE_FILE_CONTENTS
        end
      end

      context "when run with a multi-file Gist" do
        before { run "install", GIST_IDS[:multi_file] }

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
        test_single_file GIST_IDS[:cwd], Dir.pwd
      end

      context "when given a file for the home directory" do
        test_single_file GIST_IDS[:home], Dir.home
      end

      context "when given a bad ID (404)" do
        before do
          %i[puts print].each { |p| allow($stderr).to receive p }
          run "install", "bad", fail_on_exit: false
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

      context "when given a Gist with only a description" do
        before { run "install", GIST_IDS[:gist_description] }

        it "prints the description" do
          expect($stdout).to have_received(:write)
            .with(a_string_including("test description"))
        end

        it "removes the `[gistribution]` from the beginning" do
          expect($stdout).not_to have_received(:write)
            .with(a_string_including("[gistribution]"))
        end
      end

      context "when given a Gist with only `[gistribution]` in the description" do
        before { run "install", GIST_IDS[:no_gist_description] }

        it "doesn't print the description" do
          expect($stdout).not_to have_received(:write)
            .with(a_string_including("[gistribution]"))
        end
      end
    end

    context "when user inputs nothing at the installation prompt" do
      before do
        simulate_user_input "\n"
        run "install", GIST_IDS[:pub_single_file]
      end

      it "saves the file" do
        expect(File).to exist("#{TEMP}/#{FILENAME}")
      end
    end

    %w[n m].each do |ch|
      context "when user inputs `#{ch}` at the installation prompt" do
        before do
          simulate_user_input "#{ch}\n"
          run "install", GIST_IDS[:pub_single_file]
        end

        it "doesn't save the file" do
          expect(File).not_to exist("#{TEMP}/#{FILENAME}")
        end
      end
    end

    context "when a file would be overwritten" do
      let(:orig_content) { "original" }

      before do
        FileUtils.mkdir_p "#{TEMP}/dir"
        MULTI_FILENAMES.each do |filename|
          File.write("#{TEMP}/#{filename}", orig_content)
        end
      end

      let(:file1_contents) { File.read "#{TEMP}/#{MULTI_FILENAMES[0]}" }
      let(:file2_contents) { File.read "#{TEMP}/#{MULTI_FILENAMES[1]}" }

      context "when the user inputs `y` at the file overwrite prompts" do
        before do
          simulate_user_input "y\n", "y\n", "y\n"
          run "install", GIST_IDS[:multi_file]
        end

        it "downloads the files into the correct locations" do
          expect([file1_contents, file2_contents]).not_to include orig_content
        end
      end

      context "when the user inputs `n` at the file overwrite prompts" do
        before do
          simulate_user_input "y\n", "n\n", "n\n"
          run "install", GIST_IDS[:multi_file]
        end

        it "doesn't download the files" do
          expect([file1_contents, file2_contents]).to all eq orig_content
        end
      end

      context "with the `--force` flag" do
        before do
          simulate_user_input "y\n"
          run "install", "--force", GIST_IDS[:multi_file]
        end

        it "overwrites the files without prompting" do
          [file1_contents, file2_contents].each do |result|
            expect(result).not_to eq orig_content
          end
        end
      end
    end

    context "when ran with the --yes flag" do
      before { run "install", "--yes", GIST_IDS[:pub_single_file] }

      let(:file_contents) { File.read "#{TEMP}/#{FILENAME}" }

      it "downloads the file without prompting" do
        expect(file_contents).to eq SINGLE_FILE_CONTENTS
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

ENCODED_TEMP = "|tmp|gistribute_spec"

SINGLE_FILE_PATH = "#{TEMP}/#{FILENAME}".freeze
ENCODED_SINGLE_FILE_PATH = "#{ENCODED_TEMP}|#{FILENAME}".freeze
HOME_FILE_PATH = "#{Dir.home}/#{FILENAME}".freeze
ENCODED_HOME_FILE_PATH = "~|#{FILENAME}".freeze

SINGLE_FILE_CONTENT = "Line 1\nLine 2\n"
SINGLE_FILE_DESC = "Test File"

MOCK_GIST_URL = "https://gist.github.com/vinnydiehl/thisisnotarealgistid"

describe Gistribute::CLI do
  let(:octokit_client) { instance_double(Octokit::Client) }

  before do
    FileUtils.rm_rf TEMP
    FileUtils.mkdir_p TEMP

    allow(Octokit::Client).to receive(:new).and_return(octokit_client)
    allow(octokit_client).to receive(:user).and_return(double(login: "test"))
    allow(octokit_client).to receive(:create_gist).and_return(double(html_url: MOCK_GIST_URL))

    suppress_stdout
  end

  after { FileUtils.rm_rf TEMP }

  describe "#upload" do
    before { allow($stdout).to receive(:puts) }

    context "with a single file" do
      before do
        File.write(SINGLE_FILE_PATH, SINGLE_FILE_CONTENT)
        simulate_user_input "Test File\n", "y\n"
        run "upload", SINGLE_FILE_PATH
      end

      let :expected_api_call do
        {
          description: "",
          public: true,
          files: {
            "#{SINGLE_FILE_DESC} || #{ENCODED_SINGLE_FILE_PATH}" => {
              content: SINGLE_FILE_CONTENT
            }
          }
        }
      end

      it "uploads the file correctly" do
        expect(octokit_client).to have_received(:create_gist)
          .with(expected_api_call)
      end

      it "prints the URL of the Gist" do
        expect($stdout).to have_received(:puts).with MOCK_GIST_URL
      end
    end

    context "with a single file in the home directory" do
      before do
        File.write(HOME_FILE_PATH, SINGLE_FILE_CONTENT)
        simulate_user_input "Test File\n", "y\n"
        run "upload", "~/#{FILENAME}"
      end

      after { FileUtils.rm HOME_FILE_PATH }

      let :expected_api_call do
        {
          description: "",
          public: true,
          files: { "#{SINGLE_FILE_DESC} || #{ENCODED_HOME_FILE_PATH}" => { content: SINGLE_FILE_CONTENT } }
        }
      end

      it "uploads the file correctly" do
        expect(octokit_client).to have_received(:create_gist)
          .with(expected_api_call)
      end
    end

    {
      "multiple files": ["#{TEMP}/dir/file1", "#{TEMP}/file2"],
      "a directory containing multiple files": [TEMP]
    }.each do |desc, args|
      context "with #{desc} passed in" do
        let(:file1_content) { "F1L1\nF1L2\n" }
        let(:file2_content) { "F2L1\nF2L2\n" }

        before do
          FileUtils.mkdir_p "#{TEMP}/dir"
          File.write("#{TEMP}/dir/file1", file1_content)
          File.write("#{TEMP}/file2", file2_content)

          simulate_user_input "File 1\n", "File 2\n", "y\n"
          run "upload", *args
        end

        let :expected_api_call do
          {
            description: "",
            public: true,
            files: {
              "File 1 || #{ENCODED_TEMP}|dir|file1" => { content: file1_content },
              "File 2 || #{ENCODED_TEMP}|file2" => { content: file2_content }
            }
          }
        end

        it "uploads the files correctly" do
          expect(octokit_client).to have_received(:create_gist)
            .with(expected_api_call)
        end
      end
    end

    context "with the `--private` flag" do
      before do
        File.write(SINGLE_FILE_PATH, SINGLE_FILE_CONTENT)
        simulate_user_input "Test File\n", "y\n"
        run "upload", "--private", SINGLE_FILE_PATH
      end

      it "uploads a private Gist" do
        expect(octokit_client).to have_received(:create_gist)
          .with(a_hash_including(public: false))
      end
    end

    context "with the `--yes` flag" do
      before do
        File.write(SINGLE_FILE_PATH, SINGLE_FILE_CONTENT)
        simulate_user_input "Test File\n"
        run "upload", "--yes", SINGLE_FILE_PATH
      end

      it "uploads without prompting the user" do
        expect(octokit_client).to have_received(:create_gist)
      end
    end
  end
end

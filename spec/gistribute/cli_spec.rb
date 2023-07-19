# frozen_string_literal: true

require "spec_helper"

require "fileutils"

describe Gistribute::CLI do
  # Make sure we start and end with a clean `/tmp`
  before { FileUtils.rm_rf TEMP }
  after { FileUtils.rm_rf TEMP }

  let(:cli) { described_class.new }

  let(:file_contents) { File.read "#{TEMP}/#{FILENAME}" }

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

  context "when run with a single file Gist" do
    it "downloads the file into #{TEMP}" do
      suppress_stdout
      set_argv SINGLE_FILE_ID
      cli.run

      expect(file_contents).to eq "Line 1\nLine 2\n"
    end
  end
end

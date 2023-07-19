# frozen_string_literal: true

require "fileutils"

TEMP = "/tmp/gistribute_spec"

describe "gistribute" do
  # Make sure we start and end with a clean `/tmp`
  before { FileUtils.rm_rf TEMP }
  after { FileUtils.rm_rf TEMP }

  let(:bad_link) { "bad_link" }
  let(:output_404) { `gistribute #{bad_link}` }

  let(:output) { `gistribute https://gist.github.com/4346763` }
  let(:output_only_id) { `gistribute 4346763` }

  let :version do
    File.read(File.expand_path("../VERSION", __dir__)).strip
  end

  %w[--version -v].each do |flag|
    context "with the #{flag} flag" do
      it "outputs the version" do
        expect(`gistribute #{flag}`).to eq "gistribute #{version}\n"
      end
    end
  end

  context "with a single file Gist" do
    it "allows both the full URL and the Gist ID" do
      expect(output).to eq output_only_id
    end
  end
end

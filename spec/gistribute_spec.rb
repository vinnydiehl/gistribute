# frozen_string_literal: true

require "spec_helper"

describe Gistribute do
  describe "::parse_id" do
    [
      "https://gist.github.com/username/#{SINGLE_FILE_ID}",
      "https://gist.github.com/#{SINGLE_FILE_ID}",
      SINGLE_FILE_ID
    ].each do |link|
      context "when given the String: #{link}" do
        it "parses down to the Gist ID" do
          expect(described_class.parse_id(link)).to eq(SINGLE_FILE_ID)
        end
      end
    end
  end
end

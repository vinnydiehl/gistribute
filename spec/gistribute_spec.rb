# frozen_string_literal: true

require "spec_helper"

describe Gistribute do
  describe "::parse_id" do
    [PUB_SINGLE_FILE_ID, SEC_SINGLE_FILE_ID].each do |id|
      [
        "https://gist.github.com/username/#{id}",
        "https://gist.github.com/#{id}",
        id
      ].each do |link|
        context "when given the String: #{link}" do
          it "parses down to the Gist ID" do
            expect(described_class.parse_id(link)).to eq(id)
          end
        end
      end
    end
  end
end

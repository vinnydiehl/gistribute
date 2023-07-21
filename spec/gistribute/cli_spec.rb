# frozen_string_literal: true

require "spec_helper"

describe Gistribute::CLI do
  before { suppress_stdout }

  describe "#initialize" do
    context "when no argument is provided" do
      it "shows the help screen" do
        allow(Optimist).to receive :educate
        # Need to call this to reset any args that have been passed to RSpec
        set_argv
        described_class.new

        expect(Optimist).to have_received :educate
      end
    end
  end

  context "when run with the `--version` flag" do
    let :version do
      File.read(File.expand_path("../../VERSION", __dir__)).strip
    end

    it "outputs the version number" do
      expect { run "--version", fail_on_exit: false }
        .to output(a_string_matching(version)).to_stdout
    end
  end
end

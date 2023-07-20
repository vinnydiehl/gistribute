# frozen_string_literal: true

require "spec_helper"

def args_should_trigger_help_screen(*args)
  it "shows the help screen" do
    set_argv(*args)
    allow(Optimist).to receive :educate

    Gistribute::CLI.new
    expect(Optimist).to have_received :educate
  end
end

describe Gistribute::CLI do
  before { suppress_stdout }

  describe "#initialize" do
    context "when no argument is provided" do
      args_should_trigger_help_screen
    end

    context "when there are too many args" do
      args_should_trigger_help_screen "too", "many"
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

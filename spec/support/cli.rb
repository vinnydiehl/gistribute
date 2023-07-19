# frozen_string_literal: true

def set_argv(*args)
  ARGV.replace(args)
end

def args_should_trigger_help_screen(*args)
  it "shows the help screen" do
    set_argv(*args)
    allow(Optimist).to receive :educate

    Gistribute::CLI.new
    expect(Optimist).to have_received :educate
  end
end

def suppress_stdout
  allow($stdout).to receive(:write)
end

def silent_run(*args)
  suppress_stdout
  set_argv(*args)
  cli.run
end

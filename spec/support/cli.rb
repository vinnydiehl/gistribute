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

def silent_run(*args, fail_on_exit: true)
  allow($stdout).to receive(:write)

  set_argv(*args)

  begin
    cli.run
  rescue SystemExit
    fail "unexpected exit" if fail_on_exit
  end
end

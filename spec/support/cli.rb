# frozen_string_literal: true

def setup_auth
  unless File.exist?(CONFIG_FILE)
    File.write(CONFIG_FILE, ENV.fetch("GISTRIBUTE_TEST_OAUTH_TOKEN"))
  end
end

def suppress_stdout
  allow($stdout).to receive(:write)
end

def set_argv(*args)
  ARGV.replace(args)
end

def run(*args, fail_on_exit: true)
  set_argv(*args)

  begin
    cli.run
  rescue SystemExit
    fail "unexpected exit" if fail_on_exit
  end
end

def args_should_trigger_help_screen(*args)
  it "shows the help screen" do
    set_argv(*args)
    allow(Optimist).to receive :educate

    Gistribute::CLI.new
    expect(Optimist).to have_received :educate
  end
end

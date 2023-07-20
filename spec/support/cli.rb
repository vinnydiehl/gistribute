# frozen_string_literal: true

def suppress_stdout
  allow($stdout).to receive(:write)
end

def set_argv(*args)
  ARGV.replace(args)
end

def run(*args, fail_on_exit: true)
  set_argv(*args)

  begin
    Gistribute::CLI.new.run
  rescue SystemExit
    fail "unexpected exit" if fail_on_exit
  end
end

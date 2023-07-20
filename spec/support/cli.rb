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

def simulate_user_input(*inputs)
  # The reference to `inputs` ends up getting stored in the mock, since
  # it's passed in with the block. Each time `gets` is called we pull
  # one off the beginning. If there aren't enough inputs, the error
  # gets raised.
  allow($stdin).to receive(:gets) { inputs.shift || fail("blocked for input") }
end

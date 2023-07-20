# frozen_string_literal: true

require "cli/auth"
require "cli/install"

module Gistribute
  class CLI
    def initialize
      @options = Optimist.options do
        version "gistribute #{File.read(File.expand_path('../VERSION', __dir__)).strip}"
        banner version
        banner "Usage: gistribute [OPTIONS] URL_OR_ID"

        banner "\nOptions:"
        opt :yes, "install files without prompting"
        opt :version, "display version number"
        opt :help, "display this message"

        educate_on_error
      end

      authenticate

      Optimist.educate if ARGV.length != 1

      @gist_input = ARGV.first
    end

    def run
      install
    end

    def confirm?(prompt)
      print prompt
      input = $stdin.gets.strip.downcase

      input.start_with?("y") || input.empty?
    end

    # Prints an error message and exits the program.
    def exit_error(code, message)
      $stderr.puts "#{'Error'.red}: #{message}"
      exit code
    end
  end
end

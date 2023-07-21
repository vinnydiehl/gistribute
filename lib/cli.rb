# frozen_string_literal: true

require "cli/auth"
require "cli/install"
require "cli/upload"

module Gistribute
  class CLI
    def initialize
      @options = Optimist.options do
        version "gistribute #{File.read(File.expand_path('../VERSION', __dir__)).strip}"
        banner version

        banner <<~USAGE
          \nUsage:
            gistribute [OPTION]... URL_OR_ID
            gistribute [OPTION]... -u FILE...
            gistribute [OPTION]... -u DIRECTORY
        USAGE

        banner "\nOptions:"
        opt :upload, "upload a gistribution"
        opt :yes, "install files without prompting"
        opt :version, "display version number"
        opt :help, "display this message"

        educate_on_error
      end

      authenticate

      if ARGV.empty?
        Optimist.educate
      end

      if @options.upload
        @files = ARGV.dup
      else
        @gist_input = ARGV.first
      end
    end

    def run
      @options.upload ? upload : install
    end

    def confirm?(prompt)
      print prompt
      input = $stdin.gets.strip.downcase

      input.start_with?("y") || input.empty?
    end

    def get_input(prompt)
      print prompt
      $stdin.gets.strip
    end

    # Prints an error message and exits the program.
    def panic!(message)
      $stderr.puts "#{'Error'.red}: #{message}"
      exit 1
    end
  end
end

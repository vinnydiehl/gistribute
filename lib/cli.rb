# frozen_string_literal: true

require "cli/auth"
require "cli/install"
require "cli/upload"

module Gistribute
  class CLI
    def initialize
      @options = OptimistXL.options do
        version "gistribute #{File.read(File.expand_path('../VERSION', __dir__)).strip}"

        banner <<~BANNER
          #{version}

          Usage:
            gistribute SUBCOMMAND [OPTION]... INPUT

          Try `gistribute SUBCOMMAND -h` for more info. Available subcommands:
            * login: log into your GitHub account
            * logout: log out of your GitHub account
            * install: download and install files from a gistribution
            * upload: upload a new gistribution

          Options:
        BANNER

        opt :version, "display version number"
        opt :help, "display a help message"

        # Sub-commands can't access the version from this scope for whatever reason
        v = version

        subcmd :login, "log into your GitHub account"
        subcmd :logout, "log out of your GitHub account"

        subcmd :install, "install from a gistribution" do
          banner <<~BANNER
            #{v}

            Usage:
              gistribute install [OPTION]... URL_OR_ID

            Options:
          BANNER

          opt :yes, "install files without prompting"
          opt :force, "overwrite existing files without prompting"
        end

        subcmd :upload, "upload a gistribution" do
          banner <<~BANNER
            #{v}

            Usage:
              gistribute upload [OPTION]... FILE...
              gistribute upload [OPTION]... DIRECTORY

            Options:
          BANNER

          opt :description, "description for the Gist", type: :string
          opt :private, "use a private Gist"
          opt :yes, "upload files without prompting"
        end

        educate_on_error
      end

      @subcommand, @global_options, @subcommand_options =
        @options.subcommand, @options.global_options, @options.subcommand_options

      authenticate unless @subcommand == "logout"

      case @subcommand
      when "install"
        @gist_input = ARGV.first
      when "upload"
        @files = ARGV.dup
      end
    end

    def run
      case @subcommand
      when "login"
        # Do nothing, #authenticate is run from the constructor
      when "logout"
        FileUtils.rm_rf CONFIG_FILE
        puts "Logged out.".green
      else
        if ARGV.empty?
          OptimistXL.educate
        end

        eval @subcommand
      end
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

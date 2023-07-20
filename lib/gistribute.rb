# frozen_string_literal: true

require "colorize"
require "fileutils"
require "json"
require "launchy"
require "octokit"
require "optimist"

CLIENT_ID = "3f37dc8255e5ab891c3d"
CONFIG_FILE = "#{Dir.home}/.config/gistribute".freeze

module Gistribute
  class CLI
    def initialize
      @options = Optimist.options do
        version "gistribute #{File.read(File.expand_path('../VERSION', __dir__)).strip}"
        banner version
        banner "Usage: gistribute [OPTIONS] URL_OR_ID"

        banner "\nOptions:"
        opt :version, "display version number"
        opt :help, "display this message"

        educate_on_error
      end

      authenticate

      Optimist.educate if ARGV.length != 1
    end

    def authenticate
      access_token = if File.exist?(CONFIG_FILE)
        File.read(CONFIG_FILE).strip
      else
        device_res = URI.decode_www_form(
          Net::HTTP.post_form(
            URI("https://github.com/login/device/code"), "client_id" => CLIENT_ID, "scope" => "gist"
          ).body
        ).to_h

        retry_interval = device_res["interval"].to_i

        Launchy.open(device_res["verification_uri"])
        puts <<~EOS
          Opening GitHub, please enter the authentication code: #{device_res['user_code']}
          If your browser did not open, visit #{device_res['verification_uri']}
        EOS

        uri = URI("https://github.com/login/oauth/access_token")

        # Keep trying until the user enters the code or the device code expires
        token = nil
        loop do
          sleep(retry_interval)

          response = URI.decode_www_form(
            Net::HTTP.post_form(
              uri, "client_id" => CLIENT_ID, "device_code" => device_res["device_code"],
                   "grant_type" => "urn:ietf:params:oauth:grant-type:device_code"
            ).body
          ).to_h

          if (token = response["access_token"])
            File.write(CONFIG_FILE, token)
            break
          elsif response["error"] == "authorization_pending"
            # The user has not yet entered the code; keep waiting silently
            next
          elsif response["error"] == "expired_token"
            exit_error(2, "Token expired! Please try again.")
          else
            exit_error(1, response["error_description"])
          end
        end

        token
      end

      @client = Octokit::Client.new(access_token:)
      puts "Logged in as #{@client.user.login}."
      puts
    end

    def run
      print "Downloading data..."

      id = Gistribute.parse_id(ARGV.first)

      begin
        gist = @client.gist(id)
      rescue Octokit::Error => e
        $stderr.print <<~EOS.chop.red
          \rThere was an error downloading the requested Gist.
          The error is as follows:
        EOS
        $stderr.puts " #{e.response_status} #{JSON.parse(e.response_body)['message']}"

        $stderr.print "The ID that was queried is: ".red
        $stderr.puts id

        exit 1
      end

      # Regular expression word wrap to keep lines less than 80 characters. Then
      # check to see if it's empty- if not, put newlines on each side so that it
      # will be padded when displayed in the output.
      desc = gist.description.gsub(/(.{1,79})(\s+|\Z)/, "\\1\n").strip
      desc = "\n#{desc}\n" unless desc.empty?

      puts <<~EOS
        \rFinished downloading Gist from: #{gist['html_url']}
        Gist uploaded by #{
          gist.owner ? "user #{gist.owner[:login]}" : 'an anonymous user'
        }.
        #{desc}
      EOS

      gist.files.each do |filename, data|
        metadata = filename.to_s.split("||").map(&:strip)

        # | as path separator in the Gist's file name, as Gist doesn't allow the
        # usage of /.
        path = metadata.last.gsub(/[~|]/, "|" => "/", "~" => Dir.home)
        # Default description is the name of the file.
        description = metadata.size == 1 ? File.basename(path) : metadata.first

        # Handle directories that don't exist.
        FileUtils.mkdir_p File.dirname(path)
        File.write(path, data[:content])

        puts " #{'*'.green} #{description} installed."
      end
    end

    # Prints an error message and exits the program.
    def exit_error(code, message)
      $stderr.puts "#{'Error'.red}: #{message}"
      exit code
    end
  end

  # The user may enter either the full URL or just the ID, this function
  # will parse it out of the input.
  def self.parse_id(str)
    str[%r{(^|/)([[:xdigit:]]+)}, 2]
  end
end

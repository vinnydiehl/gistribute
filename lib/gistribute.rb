# frozen_string_literal: true

require "colorize"
require "fileutils"
require "json"
require "open-uri"
require "optimist"

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

      Optimist.educate if ARGV.length != 1
    end

    def run
      print "Downloading data..."

      # The user can pass in either just the ID or the entire URL to the Gist.
      id = Gistribute.parse_id(ARGV.first)

      begin
        gist = JSON.parse(URI.open("https://api.github.com/gists/#{id}").read)
      rescue OpenURI::HTTPError => e
        $stderr.print <<~EOS.red
          \rThere was an error downloading the requested Gist.
          The error is as follows:
        EOS
        $stderr.puts e

        $stderr.puts "The ID that was queried is:".red
        $stderr.puts id

        exit 1
      end

      # The JSON data contains a lot of information. The information that is
      # relevant to this program is as follows:
      #
      # {
      #   "html_url" => "Link to the Gist",
      #   "description" => "The description for the Gist",
      #
      #   "owner" => nil, # IF ANONYMOUS
      #   "owner" => {    # IF TIED TO A USER
      #     "login" => "username"
      #   },
      #
      #   "files" => {
      #     "filename of first file" => {
      #       "content" => "entire contents of the file"
      #     }
      #     # Repeat the above for every file in the Gist.
      #   }
      # }

      # Regular expression word wrap to keep lines less than 80 characters. Then
      # check to see if it's empty- if not, put newlines on each side so that it
      # will be padded when displayed in the output.
      desc = gist["description"].gsub(/(.{1,79})(\s+|\Z)/, "\\1\n").strip
      desc = "\n#{desc}\n" unless desc.empty?

      puts <<~EOS
        \rFinished downloading Gist from: #{gist['html_url']}
        Gist uploaded by #{
          gist['owner'] ? "user #{gist['owner']['login']}" : 'an anonymous user'
        }.
        #{desc}
        Beginning install...
      EOS

      gist["files"].each do |filename, data|
        metadata = filename.split("||").map(&:strip)

        # | as path separator in the Gist's file name, as Gist doesn't allow the
        # usage of /.
        path = metadata.last.gsub(/[~|]/, "|" => "/", "~" => Dir.home)
        # Default description is the name of the file.
        description = metadata.size == 1 ? File.basename(path) : metadata.first

        puts " #{'*'.green} Installing #{description}..."

        # Handle directories that don't exist.
        FileUtils.mkdir_p File.dirname(path)

        File.write(path, data["content"])
      end
    end
  end

  def self.parse_id(str)
    str[%r{(^|/)([[:xdigit:]]+)}, 2]
  end
end

# frozen_string_literal: true

module Gistribute
  class CLI
    def install
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
      gist_description = gist.description.gsub(/(.{1,79})(\s+|\Z)/, "\\1\n").strip
      gist_description = "\n#{gist_description}\n" unless gist_description.empty?

      # Process files
      files = gist.files.map do |filename, data|
        metadata = filename.to_s.split("||").map(&:strip)

        # | as path separator in the Gist's file name, as Gist doesn't allow the
        # usage of /.
        path = Gistribute.decode(metadata.last)
        # Default description is the name of the file.
        description = metadata.size == 1 ? File.basename(path) : metadata.first

        { description:, path:, content: data[:content] }
      end

      puts <<~EOS
        \rFinished downloading Gist from: #{gist.html_url}
        Gist uploaded by #{
          gist.owner ? "user #{gist.owner[:login]}" : 'an anonymous user'
        }.
        #{gist_description}
      EOS

      unless @subcommand_options.yes
        puts "Files:"

        files.each do |f|
          print "#{f[:description]}: " unless f[:description].empty?
          puts f[:path]
        end
      end

      if @subcommand_options.yes || confirm?("\nWould you like to install these files? [Yn] ")
        puts unless @subcommand_options.yes

        files.each do |f|
          if File.exist?(f[:path]) && !@subcommand_options.force &&
             !confirm?("File already exists: #{f[:path]}\nWould you like to overwrite it? [Yn] ")
            puts " #{'*'.red} #{f[:description]} skipped."
            next
          end

          # Handle directories that don't exist.
          FileUtils.mkdir_p File.dirname(f[:path])
          File.write(f[:path], f[:content])

          # If using `--yes`, we print the path in the this string rather than
          # above with the prompt
          puts " #{'*'.green} #{f[:description]} installed#{
            @subcommand_options.yes ? " to: #{f[:path]}" : '.'
          }"
        end
      else
        puts "Aborting.".red
      end
    end
  end
end

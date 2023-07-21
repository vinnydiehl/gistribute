# frozen_string_literal: true

module Gistribute
  class CLI
    def upload
      files_json = process_files(@files)

      if files_json.empty?
        panic! "No files found, aborting."
      end

      if confirm?("\nUpload these files? [Yn] ")
        gist = @client.create_gist description: "", public: true, files: files_json
      else
        puts "Aborted.".red
      end

      print "Gistribution uploaded to: ".green
      puts gist.html_url
    end

    def process_files(files)
      files.each_with_object({}) do |file, hash|
        hash.merge!(process_file file)
      end
    end

    def process_file(file)
      file = File.expand_path(file)

      if File.directory?(file)
        # Recursively process every file in the directory
        process_files(
          Dir.glob("#{file}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory? f }
        )
      else
        unless (content = File.read(file))
          panic! "Files cannot be empty."
        end

        puts "File: #{file}"
        desc = get_input("Enter pretty file name (leave blank to use raw file name): ")

        # Return a hash directly for single files
        { "#{"#{desc} || " unless desc.empty?}#{Gistribute.encode file}" => { content: } }
      end
    end
  end
end

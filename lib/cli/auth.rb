# frozen_string_literal: true

module Gistribute
  class CLI
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
  end
end

# frozen_string_literal: true

require "spec_helper"

DEVICE_RES = {
  "device_code" => "testdevicecode",
  "expires_in" => "899",
  "interval" => "1",
  "user_code" => "1337-6969",
  "verification_uri" => "https://github.com/login/device"
}.freeze

PENDING_RES = {
  "error" => "authorization_pending",
  "error_description" => "The authorization request is still pending.",
  "error_uri" => "https://docs.github.com/developers/apps/authorizing-oauth-apps#error-codes-for-the-device-flow"
}.freeze

EXPIRED_RES = {
  "error" => "expired_token",
  "error_description" => "The `device code` has expired.",
  "error_uri" => "https://docs.github.com/developers/apps/authorizing-oauth-apps#error-codes-for-the-device-flow"
}.freeze

SUCCESS_RES = {
  "access_token" => OAUTH_TOKEN,
  "scope" => "gist",
  "token_type" => "bearer"
}.freeze

def mock_oauth_response(res)
  allow(Net::HTTP).to receive(:post_form)
    .with(URI("https://github.com/login/oauth/access_token"), anything)
    .and_return(:res2)
  allow(URI).to receive(:decode_www_form)
    .with(:res2)
    .and_return(res)
end

# Hack to get the `:resX` symbols to fall through into #decode_www_form
class Symbol
  def body
    itself
  end
end

describe Gistribute::CLI do
  before do
    allow(Launchy).to receive(:open)
    allow(File).to receive(:write)
    suppress_stdout
  end

  let(:http_ok) { Net::HTTPOK.new("1.1", "200", "OK") }

  describe "#authenticate" do
    context "when there is no access key saved" do
      before do
        allow(File).to receive(:exist?).and_return(false)

        allow(Net::HTTP).to receive(:post_form)
          .with(URI("https://github.com/login/device/code"), anything)
          .and_return(:res1)
        allow(URI).to receive(:decode_www_form)
          .with(:res1)
          .and_return(DEVICE_RES.to_a)
      end

      describe "the initial output" do
        before do
          mock_oauth_response SUCCESS_RES
          run "login"
        end

        it "prints the user code" do
          expect($stdout).to have_received(:write)
            .with(a_string_matching DEVICE_RES["user_code"])
        end

        it "prints the verification URI" do
          expect($stdout).to have_received(:write)
            .with(a_string_matching DEVICE_RES["verification_uri"])
        end

        it "opens the verification URI in a browser" do
          expect(Launchy).to have_received(:open).with(DEVICE_RES["verification_uri"])
        end
      end

      describe "when the response is a success" do
        before do
          mock_oauth_response SUCCESS_RES
          allow(Octokit::Client).to receive(:new).and_call_original
          run "login"
        end

        it "writes the token to the config file" do
          expect(File).to have_received(:write).with(CONFIG_FILE, OAUTH_TOKEN)
        end

        it "logs in with Octokit" do
          expect(Octokit::Client).to have_received(:new)
            .with(a_hash_including access_token: OAUTH_TOKEN)
        end
      end

      context "when the response is timed out" do
        before do
          mock_oauth_response EXPIRED_RES
          %i[puts print].each { |p| allow($stderr).to receive p }
          run "login", fail_on_exit: false
        end

        let(:error) { "#{'Error'.red}: Token expired! Please try again." }

        it "displays an error" do
          expect($stderr).to have_received(:puts).with(error)
        end
      end
    end
  end

  describe "the `logout` subcommand" do
    before do
      allow(FileUtils).to receive(:rm_rf)
      run "logout"
    end

    it "deletes the auth token" do
      expect(FileUtils).to have_received(:rm_rf).with(CONFIG_FILE)
    end
  end
end

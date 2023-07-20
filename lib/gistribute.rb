# frozen_string_literal: true

require "colorize"
require "fileutils"
require "json"
require "launchy"
require "octokit"
require "optimist"

require "cli"

CLIENT_ID = "3f37dc8255e5ab891c3d"
CONFIG_FILE = "#{Dir.home}/.config/gistribute".freeze

module Gistribute
  # The user may enter either the full URL or just the ID, this function
  # will parse it out of the input.
  def self.parse_id(str)
    str[%r{(^|/)([[:xdigit:]]+)}, 2]
  end
end

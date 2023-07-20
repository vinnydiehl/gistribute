# frozen_string_literal: true

require "gistribute"

# Get OAuth token from environment if there is none
unless File.exist?(CONFIG_FILE)
  File.write(CONFIG_FILE, ENV.fetch("GISTRIBUTE_TEST_OAUTH_TOKEN"))
end

# Yes, this could be leaked in CI, but it's just a gist scoped token for a dummy account
OAUTH_TOKEN = File.read(CONFIG_FILE).freeze

# Include all files in spec/support
Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }

RSpec.configure do |config|
  # Add `focus: true` hash parameter to a describe/context/it block
  # to only run the specs in that block
  config.filter_run_when_matching :focus

  # Fuubar
  unless ARGV.any? { |arg| arg.include? "-f" }
    config.add_formatter "Fuubar"
    config.fuubar_progress_bar_options = { format: "  %c/%C |%b>%i|%e " }
  end

  # More verbose output if only running one spec
  config.default_formatter = "doc" if config.files_to_run.one?

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, fix the order by providing the seed,
  # which is printed after each run, e.g. --seed 1234
  config.order = :random
  Kernel.srand config.seed
end

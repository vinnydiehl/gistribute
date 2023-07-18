# frozen_string_literal: true

Gem::Specification.new do |gem|
  gem.name = "gistribute"
  gem.version = File.read(File.expand_path("VERSION", __dir__)).strip

  gem.author = "Vinny Diehl"
  gem.email = "vinny.diehl@gmail.com"
  gem.homepage = "https://github.com/vinnydiehl/gistribute"
  gem.metadata["rubygems_mfa_required"] = "true"

  gem.license = "MIT"

  gem.summary = "GitHub Gist based file distribution."
  gem.description = "Distribute files simply using GitHub Gist."

  gem.bindir = "bin"
  gem.executables = %w[gistribute]
  gem.files = `git ls-files -z`.split "\x0"

  gem.add_dependency "colorize", "~> 1.0"
  gem.add_development_dependency "fuubar", "~> 2.0"
  gem.add_development_dependency "rspec", "~> 3.12"
  gem.add_development_dependency "rubocop", "~> 1.54"
  gem.add_development_dependency "rubocop-rspec", "~> 2.22"
end

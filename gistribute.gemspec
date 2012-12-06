Gem::Specification.new do |gem|
  gem.name = "gistribute"
  gem.version = File.read(File.expand_path("../VERSION", __FILE__)).strip

  gem.author = "Vinny Diehl"
  gem.email = "vinny.diehl@gmail.com"
  gem.homepage = "https://github.com/gbchaosmaster/gistribute"

  gem.license = "MIT"

  gem.summary = "GitHub Gist based file distribution."
  gem.description = "Distribute files simply using GitHub Gist."

  gem.bindir = "bin"
  gem.executables = %w[gistribute]

  gem.files = Dir["bin/**/*"] + %w[
    LICENSE Rakefile README.md VERSION gistribute.gemspec
  ]

  gem.add_dependency "json", "~> 1.7"
  gem.add_dependency "nutella", "~> 0.10"
  gem.add_dependency "colorize", "~> 0.5"
end

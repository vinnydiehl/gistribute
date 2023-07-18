Gem::Specification.new do |gem|
  gem.name = "gistribute"
  gem.version = File.read(File.expand_path("../VERSION", __FILE__)).strip

  gem.author = "Vinny Diehl"
  gem.email = "vinny.diehl@gmail.com"
  gem.homepage = "https://github.com/vinnydiehl/gistribute"

  gem.license = "MIT"

  gem.summary = "GitHub Gist based file distribution."
  gem.description = "Distribute files simply using GitHub Gist."

  gem.bindir = "bin"
  gem.executables = %w[gistribute]
  gem.test_files = Dir["spec/**/*"]
  gem.files = `git ls-files -z`.split "\x0"

  gem.add_dependency "colorize", "~> 1.0"
  gem.add_development_dependency "fuubar", "~> 2.0"
  gem.add_development_dependency "rspec", "~> 3.12"
end

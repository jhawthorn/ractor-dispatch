# frozen_string_literal: true

require_relative "lib/ractor/dispatch/version"

Gem::Specification.new do |spec|
  spec.name = "ractor-dispatch"
  spec.version = Ractor::Dispatch::VERSION
  spec.authors = ["John Hawthorn"]
  spec.email = ["john@hawthorn.email"]

  spec.summary = "Dispatch work to a specific Ractor and get results back"
  spec.description = "A lightweight library for dispatching work to a specific Ractor. Useful as an escape hatch when code running in non-main Ractors needs to execute something only the main Ractor can do."
  spec.homepage = "https://github.com/jhawthorn/ractor-dispatch"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0.dev"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jhawthorn/ractor-dispatch"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end

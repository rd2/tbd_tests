lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tbd_tests/version"

Gem::Specification.new do |s|
  # Specify which files should be added to the gem when it is released.
  # "git ls-files -z" loads files in the RubyGem that have been added into git.
  s.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end

  s.name                     = "tbd_tests"
  s.version                  = TBD_Tests::VERSION
  s.license                  = "BSD-3-Clause"
  s.summary                  = "Testing TBD"
  s.description              = "Extended testing of the Ruby gem & OpenStudio "\
                               "measure 'Thermal Bridging & Derating (TBD)'"
  s.authors                  = ["Denis Bourgeois & Dan Macumber"]
  s.email                    = ["denis@rd2.ca"]
  s.platform                 = Gem::Platform::RUBY
  s.homepage                 = "https://github.com/rd2/tbd_tests"
  s.bindir                   = "exe"
  s.require_paths            = ["lib"]
  s.executables              = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.required_ruby_version    = [">= 2.5.0", "< 4"]
  s.metadata                 = {}

  s.add_development_dependency "tbd",         "3.5.0"
  s.add_development_dependency "json-schema", "~> 4"
  s.add_development_dependency "rake",        "~> 13.0"
  s.add_development_dependency "rspec",       "~> 3.11"
  s.add_development_dependency "parallel",    "~> 1.19"

  if /^2.5/.match(RUBY_VERSION)
    s.required_ruby_version = "~> 2.5.0"

    s.add_development_dependency "bundler",     "~> 2.1"

    s.add_development_dependency "openstudio-common-measures",    "~> 0.2.1"
    s.add_development_dependency "openstudio-model-articulation", "~> 0.2.1"
  elsif /^2.7/.match(RUBY_VERSION)
    s.required_ruby_version = "~> 2.7.0"

    s.add_development_dependency "bundler",     "~> 2.1"

    s.add_development_dependency "openstudio-common-measures",    "~> 0.5.0"
    s.add_development_dependency "openstudio-model-articulation", "~> 0.5.0"
  else
    s.required_ruby_version = "~> 3.2.2"

    s.add_development_dependency "bundler",     "~> 2.4.10"

    s.add_development_dependency "openstudio-common-measures",    "~> 0.12.3"
    s.add_development_dependency "openstudio-model-articulation", "~> 0.12.2"
  end

  s.metadata["homepage_uri"   ] = s.homepage
  s.metadata["source_code_uri"] = "#{s.homepage}/tree/v#{s.version}"
  s.metadata["bug_tracker_uri"] = "#{s.homepage}/issues"
end

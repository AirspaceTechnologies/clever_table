$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "clever_table/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "clever_table"
  s.version     = CleverTable::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of CleverTable."
  s.description = "TODO: Description of CleverTable."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2"

  s.add_development_dependency "pg"
  s.add_development_dependency "rspec-rails", "~> 3.4.0"
  s.add_development_dependency "test-unit"
  s.add_development_dependency "capybara-screenshot"
  s.add_development_dependency "poltergeist"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "factory_girl"
end

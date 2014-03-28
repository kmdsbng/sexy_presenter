$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sexy_presenter/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sexy_presenter"
  s.version     = SexyPresenter::VERSION
  s.authors     = ["Yoshihiro Kameda"]
  s.email       = ["kameda.sbng@gmail.com"]
  s.homepage    = ""
  s.summary     = "A Rails presentation layer library powered by Refinements."
  s.description = "A Rails presentation layer library powered by Refinements."

  s.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0"

end

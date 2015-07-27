$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "deserializer/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "deserializer"
  s.version     = Deserializer::VERSION
  s.authors     = ["Greg Orlov"]
  s.email       = ["gaorlov@gmail.com"]
  s.homepage    = ""
  s.summary     = "deserialization"
  s.description = "conversion from complexy write params to a json blob that an AR model can consume"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

end
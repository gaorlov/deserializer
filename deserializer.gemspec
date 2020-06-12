# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deserializer/version'

Gem::Specification.new do |s|
  s.name        = "deserializer"
  s.version     = Deserializer::VERSION
  s.authors     = ["Greg Orlov"]
  s.email       = ["gaorlov@gmail.com"]
  s.homepage    = "https://github.com/gaorlov/deserializer"
  s.summary     = "deserialization"
  s.description = "conversion from complexy write params to a json blob that an AR model can consume"
  s.license     = "MIT"

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|s|features)/})
  s.require_paths = ["lib"]

  s.add_dependency "activesupport", ">= 5.0.0"

  s.add_development_dependency "rake"
  s.add_development_dependency "m", "~> 1.3.1"
end
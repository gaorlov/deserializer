$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start

require 'deserializer'

test_libs_path = File.expand_path("../lib", __FILE__)
Dir[File.join(test_libs_path, "/**/*.rb")].each do |file|
  puts file
  require file
end

require 'minitest/autorun'

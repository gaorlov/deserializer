require "deserializer/version"
require 'active_support'
require 'active_support/concern'

module Deserializer
  autoload :Associatable, 		'deserializer/associatable'
  autoload :Base,               'deserializer/base'
  autoload :DeserializerError,  'deserializer/deserializer_error'
end

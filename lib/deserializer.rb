require "deserializer/version"
require 'active_support'
require 'active_support/concern'

module Deserializer
  autoload :Attribute,          'deserializer/attribute'
  autoload :Attributable,       'deserializer/attributable'
  autoload :Base,               'deserializer/base'
  autoload :DeserializerError,  'deserializer/deserializer_error'
end

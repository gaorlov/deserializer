require "deserializer/version"
require 'active_support'
require 'active_support/concern'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/class/attribute'

module Deserializer
  autoload :Attribute,          'deserializer/attribute'
  autoload :Attributable,       'deserializer/attributable'
  autoload :Base,               'deserializer/base'
  autoload :DeserializerError,  'deserializer/deserializer_error'
  autoload :JsonApi,            'deserializer/json_api'
end

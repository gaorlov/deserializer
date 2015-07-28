module Deserializer
  class Base
    class << self
      attr_accessor :attrs
    end

    # deserializer interface functions

    def self.attributes(*attrs)
      self.attrs ||= {}
      attrs.each do |attr|
        self.attrs[attr] = attr
      end
    end

    def self.attribute(attr, options = {})
      self.attrs ||= {}
      key = options.fetch(:key, attr)
      self.attrs[key] = attr
    end

    def self.has_one( target, opts = {})
      deserializer = opts[:deserializer]

      raise "has_one associations need a deserilaizer" unless deserializer

      attrs[target] = deserializer

    end

    def self.has_many(*args)
      raise "has_many is currently unsupported."
    end

    def self.belongs_to(*args)
      raise "belongs_to is urrently unsupported"
    end

    attr_reader     :object

    # deserializer usage functions

    def self.from_params( params = {} )
      self.new({}, params).deserialize
    end

    def self.permitted_params
      attrs.keys
    end

    def deserialize
      self.class.attrs.each do |param_key, object_key|
        # this checks if the object_key is a class that inherits from Deserializer
        if object_key.is_a?(Class) && object_key < Deserializer::Base
          deseralize_nested(param_key, object_key)
        else
          object[object_key] = params[param_key]
        end
      end
      object
    end

    protected

    attr_accessor   :params
    attr_writer     :object


    def initialize( object = {}, params = {})
      self.params = params.deep_symbolize_keys
      self.object = object
    end

    def deseralize_nested(association, deserializer)
      if self.respond_to? association
        
        target = self.send( association )
        
        unless target.is_a? Hash
          target = object[target] = {}
        end
      else
        target = object[association] = {}
      end

      deserializer.new( target, params[association] ).deserialize
    end
  end
end
module Deserializer
  class Base
    class << self
      attr_accessor :attrs
    
      # deserializer interface functions

      def attributes(*attrs)
        self.attrs ||= {}
        attrs.each do |attr|
          self.attrs[attr] = attr
        end
      end

      def attribute(attr, options = {})
        self.attrs ||= {}
        key = options.fetch(:key, attr)
        self.attrs[key] = attr
      end

      def has_one( target, opts = {})
        deserializer = opts[:deserializer]

        unless deserializer
          raise DeserializerError, class: self, message: "has_one associations need a deserilaizer" 
        end

        self.attrs[target] = deserializer
      end

      def has_many(*args)
        raise DeserializerError, class: self, message: "has_many is currently unsupported."
      end

      def belongs_to(*args)
        raise DeserializerError, class: self, message: "belongs_to is currently unsupported."
      end

      # deserializer usage functions

      def from_params( params = {} )
        self.new({}, params).deserialize
      end

      def permitted_params
        self.attrs.keys
      end

    end

    attr_reader     :object

    def deserialize
      self.class.attrs.each do |param_key, object_key|
        # don't bother with keys that aren't in params
        next unless params.has_key? param_key

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
      unless params
        raise DeserializerError, class: self.class, message: "params cannot be nil"
      end

      self.params = params
      self.object = object
    end

    def deseralize_nested(association, deserializer)
      if self.respond_to? association
        
        target = self.send( association )
        
        unless target.is_a? Hash
          target = object[target] ||= {}
        end
      else
        target = object[association] ||= {}
      end

      deserializer.new( target, params[association] ).deserialize
    end
  end
end
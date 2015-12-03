module Deserializer
  class Base

    ## has_one, nested, etc associations
    include Deserializer::Associatable

    class << self
      attr_accessor :attrs, :nested_attrs
    
      # deserializer interface functions

      def attributes(*attrs)
        self.attrs ||= {}
        attrs.each do |attr|
          self.attrs[attr] = {attr: attr, options: {}}
        end
      end

      def attribute(attr, options = {})
        self.attrs ||= {}
        key = options.fetch(:key, attr)
        self.attrs[key] = {attr: attr, options: options}
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
        if object_key[:deserializer]
          deseralize_association(param_key, object_key[:deserializer])
        else
          attribute = object_key[:attr]
          options   = object_key[:options]

          assign_value attribute, params[param_key], options
        end
      end

      self.class.nested_attrs ||= {}
      self.class.nested_attrs.each do |target, options|
        deserialize_nested target, options[:deserializer]
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

    def deseralize_association(association, deserializer)
      # check for method defining the target object (something, in the example below)
      #
      # class ExampleDeserializer < Deserializer::Base
      #   has_one :something, deserializer: SomethingDeserializer
      #   
      #   def something
      #     object
      #   end
      # end

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

    def deserialize_nested( target, deserializer )
      target = object[target] ||= {}
      deserializer.new( target, params ).deserialize
    end

    def assign_value( attribute, value, options = {} )
      if options[:ignore_empty] && empty?(value)
        return
      end
      if options[:convert_with]
        method = options[:convert_with]
        if self.respond_to? method
          self.object[attribute] = self.send method, value
          return
        end
      end
      # other options go here
      
      self.object[attribute] = value
      
    end

    def empty?(value)
      !value ||
      value == "" ||
      value == {} ||
      value == []
    end
  end
end

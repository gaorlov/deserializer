module Deserializer
  class Base

    ## atribute, has_one, nested, etc associations
    include Deserializer::Attributable

    class_attribute :__attrs
    self.__attrs = {}
    class << self
      
      # deserializer usage functions

      def from_params( params = {} )
        new( params ).deserialize
      end

      def permitted_params
        __attrs.keys
      end
    end

    attr_reader     :object

    def deserialize

      object ||= {}

      # deserialize
      self.class.__attrs.each do |_, attr|
        object.merge!( attr.to_hash( params, self ) ) do |key, old_value, new_value|
          # in the case that 2 has_ones merge into the same key. Not sure i want to support this
          if old_value.is_a?( Hash ) && new_value.is_a?( Hash )
            old_value.merge new_value
          else
            new_value
          end
        end
      end
      object
    end

    protected

    attr_accessor   :params
    attr_writer     :object

    def initialize( params = {})
      unless params
        raise DeserializerError, class: self.class, message: "params cannot be nil"
      end

      self.params = params
      self.object = {}
    end
  end
end
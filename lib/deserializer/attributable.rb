module Deserializer
  module Attributable
    extend ActiveSupport::Concern

    included do
      class << self
        # deserializer interface functions

        def attributes( *attrs )
          self.__attrs ||= []
          attrs.each do |attr|
            __attrs << Attribute::Attribute.new( Attribute::ValueAttribute, attr, {} )
          end
        end

        def attribute( name, opts = {} )
          self.__attrs ||= []
          __attrs << Attribute::Attribute.new( Attribute::ValueAttribute, name, opts )
        end

        def has_one( name, opts = {} )
          unless opts[:deserializer]
            raise DeserializerError, class: self, message: "has_one associations need a deserilaizer" 
          end

          self.__attrs ||= []
          __attrs << Attribute::Attribute.new( Attribute::HasOneAssociation, name, opts )
        end

        def has_many( name, opts = {} )
          unless opts[:deserializer]
            raise DeserializerError, class: self, message: "has_many associations need a deserilaizer" 
          end

          self.__attrs ||= []
          __attrs << Attribute::Attribute.new( Attribute::HasManyAssociation, name, opts )
        end

        def belongs_to( *args )
          raise DeserializerError, class: self, message: "belongs_to is unsupported."
        end

        def nests( name, opts = {} )
          unless opts[:deserializer]
            raise DeserializerError, class: self, message: "nested associations need a deserilaizer" 
          end

          self.__attrs ||= []
          __attrs << Attribute::Attribute.new( Attribute::NestedAssociation, name, opts )
        end
      end
    end
  end
end
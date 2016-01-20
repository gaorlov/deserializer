module Deserializer
  module Attributable
    extend ActiveSupport::Concern

    included do
      class << self
        # deserializer interface functions

        def attributes( *attrs )
          self.__attrs = __attrs.dup
          attrs.each do |attr|
            attribute( attr, {} )
          end
        end

        def attribute( name, opts = {} )
          attribute = Attribute::Attribute.new( Attribute::ValueAttribute, name, opts )
          self.__attrs = __attrs.merge attribute.key => attribute
        end

        def has_one( name, opts = {} )
          unless opts[:deserializer]
            raise DeserializerError, class: self, message: "has_one associations need a deserilaizer" 
          end
          
          attribute = Attribute::Attribute.new( Attribute::HasOneAssociation, name, opts )
          self.__attrs = __attrs.merge attribute.key => attribute
        end

        def has_many( name, opts = {} )
          unless opts[:deserializer]
            raise DeserializerError, class: self, message: "has_many associations need a deserilaizer" 
          end

          attribute = Attribute::Attribute.new( Attribute::HasManyAssociation, name, opts )
          self.__attrs = __attrs.merge attribute.key => attribute
        end

        def belongs_to( *args )
          raise DeserializerError, class: self, message: "belongs_to is unsupported."
        end

        def nests( name, opts = {} )
          unless opts[:deserializer]
            raise DeserializerError, class: self, message: "nested associations need a deserilaizer" 
          end

          attribute = Attribute::Attribute.new( Attribute::NestedAssociation, name, opts )
          self.__attrs = __attrs.merge attribute.key => attribute
        end
      end
    end
  end
end
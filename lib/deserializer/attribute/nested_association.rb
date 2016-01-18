module Deserializer
  module Attribute
    class NestedAssociation < Association

      def to_hash( params )
        { name => deserializer.from_params( params ) }
      end
    end
  end
end
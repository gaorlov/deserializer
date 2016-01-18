module Deserializer
  module Attribute
    class HasManyAssociation < Association

      def value( params )
        target = []
        params[key].each do |association_datum|
          target << deserializer.from_params( association_datum )
        end
        target
      end
    end
  end
end
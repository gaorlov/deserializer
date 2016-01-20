module Deserializer
  module Attribute
    class HasOneAssociation < Association

      def to_hash( params )
        return {} unless params[name]
        value = deserializer.from_params( params[key] )
   
        if object.respond_to? name
          
          target = object.send( name )
          
          # has_one :thing, deserializer: ThingDeserializer
          #
          # def thing
          #   object
          # end
          if target == object.object
            return value

          # has_one :thing, deserializer: GnihtDeserializer
          #
          # def thing
          #   :some_other_key
          # end
          else
            return { target => value }
          end
        else
          return { key => value }
        end
      end
    end
  end
end
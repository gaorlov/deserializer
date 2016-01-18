module Deserializer
  module Attribute
    class ValueAttribute < Base

      def value( params )
        value = params[key]

        if opts[:ignore_empty] && empty?(value)
          return :ignore
        end
        
        if opts[:convert_with]
          method = opts[:convert_with]
          if object.respond_to? method
            return object.send method, value
          end
        end
        # other options go here
        
        value
      end

      private

      def empty?(value)
        !value ||
        value == "" ||
        value == {} ||
        value == []
      end
    end
  end
end
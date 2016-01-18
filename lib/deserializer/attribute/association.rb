module Deserializer
  module Attribute
    class Association < Base
    
      private

      def deserializer
        opts[:deserializer]
      end
    end
  end
end
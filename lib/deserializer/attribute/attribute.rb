module Deserializer
  module Attribute
    class Attribute
      def initialize( type, name, opts )
        @type = type
        @name = name
        @opts = opts
      end

      def key
        @opts.fetch :key, @name
      end

      def to_hash( params, object )
        attribute = @type.new( @name, @opts, object )
        attribute.to_hash( params )
      end
    end
  end
end
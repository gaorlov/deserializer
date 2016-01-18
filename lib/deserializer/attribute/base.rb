module Deserializer
  module Attribute
    class Base

      attr_reader :name

      def initialize( name, opts = {}, object )
        self.name   = name
        self.opts   = opts
        self.object = object
      end

      # simple object
      # { key => value }

      # has_* object
      # { key => { deserialized obejct }}

      # has_one :whatever; where def wahtever{ object }
      # { object } 
      def to_hash( params )
        return {} unless params.has_key? key
        tuple( params )
      end

      private

      attr_accessor :opts, :value, :object
      attr_writer :name

      def key
        @key ||= opts.fetch :key, name
      end

      def tuple( params = {} )
        value = value( params )
        if value == :ignore
          {}
        else
          { name => value }
        end
      end

      def value( params = {} )
        return "not implemented"
      end
    end
  end
end
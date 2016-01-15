module Deserializer
  class Base

    ## has_one, nested, etc associations
    include Deserializer::Attributable

    class << self
      attr_accessor :__attrs

      # deserializer usage functions

      def from_params( params = {} )
        self.new( params ).deserialize
      end

      def permitted_params
        self.__attrs.map(&:name)
      end
    end

    attr_reader     :object

    def deserialize

      target = {}

      # deserialize
      self.class.attrs.each do |attr|
        target.merge attr.to_hash(params)
      end
    end

    protected

    attr_accessor   :params
    attr_writer     :object

    def initialize( params = {})
      unless params
        raise DeserializerError, class: self.class, message: "params cannot be nil"
      end

      self.params = params
    end
  end
end


module Deserializer
  class Attribute

    attr_reader :name

    def initialize( name, opts = {} )
      self.name = name
      self.opts = opts
    end

    # simple object
    # { key => value }

    # has_* object
    # { key => { deserialized obejct }}

    # has_one :whatever; where def wahtever{ object }
    # { object } 
    def to_hash( params )
      return {} unless params[key]
      tuple( params )
    end

    private

    attr_accessor :opts, :value
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

module Deserializer
  class AssociationAttribute < Attribute
    
    private

    def deserializer
      opts[:deserializer]
    end
  end
end

module Deserializer
  class HasManyAttribute < AssociationAttribute

    def value( params )
      target = []
      params[key].each do |association_datum|
        target << deserializer.from_params( association_datum )
      end

    end
  end
end

module Deserializer
  class HasOneAttribute < AssociationAttribute

    def value( params )
      # not sure what to do about this
      if self.respond_to? association
        
        target = self.send( association )
        
        unless target.is_a? Hash
          target = object[target] ||= {}
        end
      else
        target = object[association] ||= {}
      end

      # have you tried merging?
      deserializer.from_params( params[key] )
    end
  end
end

module Deserializer
  class NestedAttribute < AssociationAttribute

    def to_hash( params )
      { name => deserializer.from_params( params ) }
    end
  end
end


module Deserializer
  class ValueAttribute < Attribute

    def value( params )
      value = params[name]
      if opts[:ignore_empty] && empty?(value)
        return :ignore
      end
      # what do? 
      if opts[:convert_with]
        method = opts[:convert_with]
        if self.respond_to? method
          return self.send method, value
        end
      end
      # other options go here
      
      value
    end

    private

    def self.empty?(value)
      !value ||
      value == "" ||
      value == {} ||
      value == []
    end
  end
end
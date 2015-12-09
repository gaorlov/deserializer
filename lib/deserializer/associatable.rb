module Deserializer
  module Associatable
    extend ActiveSupport::Concern

    included do
      class << self
        def has_one( target, opts = {})
          deserializer = opts[:deserializer]

          unless deserializer
            raise DeserializerError, class: self, message: "has_one associations need a deserilaizer" 
          end

          self.associations ||= {}
          self.associations[target] = { deserializer: deserializer, type: :has_one }
        end

        def has_many( target, opts = {})
          deserializer = opts[:deserializer]

          unless deserializer
            raise DeserializerError, class: self, message: "has_many associations need a deserilaizer" 
          end

          self.associations ||= {}
          self.associations[target] = { deserializer: deserializer, type: :has_many }
        end

        def belongs_to(*args)
          raise DeserializerError, class: self, message: "belongs_to is unsupported."
        end

        def nests(target, opts = {})
          deserializer = opts[:deserializer]

          unless deserializer
            raise DeserializerError, class: self, message: "nested associations need a deserilaizer" 
          end

          self.nested_attrs ||= {}
          self.nested_attrs[target] = { deserializer: deserializer }
        end
      end
    end
  end
end
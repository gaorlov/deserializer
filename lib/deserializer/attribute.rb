module Deserializer
  module Attribute
    autoload :Base,               "deserializer/attribute/base"
    autoload :Association,        "deserializer/attribute/association"
    autoload :Attribute,          "deserializer/attribute/attribute"
    autoload :HasManyAssociation, "deserializer/attribute/has_many_association"
    autoload :HasOneAssociation,  "deserializer/attribute/has_one_association"
    autoload :NestedAssociation,  "deserializer/attribute/nested_association"
    autoload :ValueAttribute,     "deserializer/attribute/value_attribute"
  end
end
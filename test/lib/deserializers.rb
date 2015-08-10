class BasicDeserializer < Deserializer::Base
  attributes  :user_id,
              :text
end

class AttributeDeserializer < Deserializer::Base
  attribute :user_id, key: :user
  attribute :text
end

class VanillaHasOneDeserializer < Deserializer::Base
  attribute   :internal, key: :external

  has_one :params, deserializer: BasicDeserializer
  
end

class EmptiableAttributeDeserializer < Deserializer::Base
  attribute :emptiable, ignore_empty: true
  attribute :nonemptiable, ignore_empty: false
  
  attribute :emptiable_with_key,  ignore_empty: true, key: :empty
  attribute :nonemptiable_with_key,  ignore_empty: false, key: :non_empty
end

class HasOneWithTargetDeserializer < Deserializer::Base
  attribute   :internal, key: :external

  has_one :thing, deserializer: ::BasicDeserializer
  
  def thing
    :user_info
  end
end

class OtherThingDeserializer < Deserializer::Base
  attributes  :attr1,
              :attr2
end

class TricksyDeserializer < Deserializer::Base
  attribute   :internal, key: :external

  has_one :thing, deserializer: ::BasicDeserializer
  
  has_one :other_thing, deserializer: ::OtherThingDeserializer

  def thing
    :user_info
  end

  def other_thing
    :user_info
  end
end

class ExtraTricksyDeserializer < Deserializer::Base
  attribute   :internal, key: :external

  has_one :thing, deserializer: ::BasicDeserializer
  
  has_one :other_thing, deserializer: ::OtherThingDeserializer

  def other_thing
    :thing
  end
end

class HasOneWithObjectTargetDeserializer < Deserializer::Base
  attribute   :internal, key: :external

  has_one :thing, deserializer: ::BasicDeserializer

  has_one :other_thing, deserializer: ::OtherThingDeserializer
  
  def thing
    object
  end

  def other_thing
    object
  end
end
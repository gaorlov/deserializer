require 'minitest_helper'

class DeserializerTest < Minitest::Test

  def setup
    @params = { user: 6,
                user_id: 6,
                text: "text",
                i_sholdnt_be_here: :should_i_now}

  end

  def test_no_nil_params
    assert_raises Deserializer::DeserializerError do
      BasicDeserializer.from_params nil
    end
  end

  def test_from_params
    assert_equal ({user_id: 6, text: "text"}) , BasicDeserializer.from_params( @params )
  end

  def test_permitted_params
    assert_equal [:user_id, :text] , BasicDeserializer.permitted_params
  end

  def test_does_not_eat_false_or_nil_values
    params = {  user_id: nil,
                text: false,
                i_sholdnt_be_here: :should_i_now }
                
    assert_equal ({user_id: nil, text: false}) , BasicDeserializer.from_params( params )
  end

  def test_permitted_params_with_attr_key
    assert_equal [:user, :text] , AttributeDeserializer.permitted_params
  end

  def test_attribute
    assert_equal "text", AttributeDeserializer.from_params( @params )[:text]
  end

  def test_attribute_with_key
    assert_equal 6, AttributeDeserializer.from_params( @params )[:user_id]
  end

  def test_ignore_empty_option
    d = EmptiableAttributeDeserializer
    
    assert_equal ({ emptiable: true }), d.from_params( emptiable: true )
    assert_equal ({ nonemptiable: true }), d.from_params( nonemptiable: true )

    [false, nil, "", [], {}].each do |empty_value|
      assert_equal ({}), d.from_params( emptiable: empty_value )
      assert_equal ({ nonemptiable: empty_value }), d.from_params( nonemptiable: empty_value )
    end
  end

  def test_ignore_empty_with_key
    d = EmptiableAttributeDeserializer
    
    assert_equal ({ emptiable_with_key: true }), d.from_params( empty: true )
    assert_equal ({ nonemptiable_with_key: true }), d.from_params( non_empty: true )

    [false, nil, "", [], {}].each do |value|
      assert_equal ({}), d.from_params( key: value )
      assert_equal ({ nonemptiable_with_key: value }), d.from_params( non_empty: value )
    end
  end

  def test_undefined_params_dont_come_through
    assert_equal nil, AttributeDeserializer.from_params( @params )[:i_shouldnt_be_here]
  end

  def test_has_one
    expected = { internal: :thing, params: { user_id: 6, text: "text" }}
    params   = { external: :thing, params: @params }
    assert_equal expected, VanillaHasOneDeserializer.from_params( params )
  end

  def test_has_one_requires_deserializer
    assert_raises Deserializer::DeserializerError do
      BasicDeserializer.has_one :splosion
    end
  end

  def test_has_one_with_key_target
    expected = { internal: :thing, user_info: { user_id: 6, text: "text" }}
    params   = { external: :thing, thing: @params }
    assert_equal expected, HasOneWithTargetDeserializer.from_params( params )
  end

  def test_can_combine_two_has_ones_into_a_third_key
    expected = { internal: :thing, user_info: { user_id: 6, text: "text", attr1: :blah, attr2: :blech }}
    params   = { external: :thing, thing: @params, other_thing: {attr1: :blah, attr2: :blech} }
    assert_equal expected, TricksyDeserializer.from_params( params )
  end


  def test_can_merge_a_has_one_into_another
    expected = { internal: :thing, thing: { user_id: 6, text: "text", attr1: :blah, attr2: :blech }}
    params   = { external: :thing, thing: @params, other_thing: {attr1: :blah, attr2: :blech} }
    assert_equal expected, ExtraTricksyDeserializer.from_params( params )
  end


  def test_merge_has_one_into_object
    expected = { internal: :thing, user_id: 6, text: "text", attr1: :blah, attr2: :blech }
    params   = { external: :thing, thing: @params, other_thing: {attr1: :blah, attr2: :blech} }
    assert_equal expected, HasOneWithObjectTargetDeserializer.from_params( params )
  end

  def test_belongs_to_unpermitted
    assert_raises Deserializer::DeserializerError do
      BasicDeserializer.belongs_to :explody
    end
  end

  def test_supports_conversions
    expected = { real_range: (1..4), bad_range: (1..1)}
    params   = { real_range: [1, 12, 4], bad_range: 1}

    assert_equal expected, ConversionDeserializer.from_params( params )
  end

  def test_supports_conversions_with_key
    expected = { real_range: (1..4), bad_range: (1..1)}
    params   = { real: [1, 4], bad: 1}

    assert_equal expected, KeyedConversionDeserializer.from_params( params )
  end

  def test_supports_conversions_with_ignore_empty
    expected = { real_range: (1..4)}
    params   = { real: [1, 4], bad: nil}

    assert_equal expected, NillableConversionDeserializer.from_params( params )
  end

  def test_using_requires_deserializer
     assert_raises Deserializer::DeserializerError do
      BasicDeserializer.nests :splosion
    end
  end

  def test_supports_nested
    params   = { id: 1, attr_1: "blah", attr_2: "something" }
    expected = { id: 1, attr_1: "blah", nested_object: { name: "blah", attr_2: "something" } }

    assert_equal expected, NestableDeserializer.from_params( params )
  end

  def test_has_many_requires_deserializer
     assert_raises Deserializer::DeserializerError do
      BasicDeserializer.has_many :splosions
    end
  end

  def test_supports_has_many
    params   = { id: 1, attributes: [{user: 6, text: "lol"}, {user: 6, text: "something"}] }
    expected = { id: 1, attributes: [{user_id: 6, text: "lol"}, {user_id: 6, text: "something"}] }

    assert_equal expected, HasManyDeserializer.from_params( params )
  end

  def test_has_many_handles_no_input
    assert_equal ({}), HasManyDeserializer.from_params( {} )
  end

  def test_has_one_handles_no_input
    assert_equal ({}), VanillaHasOneDeserializer.from_params( {} )
  end

    def test_nested_handles_no_input
    assert_equal ({nested_object: {}}), NestableDeserializer.from_params( {} )
  end
end
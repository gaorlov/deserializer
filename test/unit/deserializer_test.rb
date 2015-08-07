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

  def test_has_many_unpermitted
    assert_raises Deserializer::DeserializerError do
      BasicDeserializer.has_many :explodies
    end
  end

  def test_belongs_to_unpermitted
    assert_raises Deserializer::DeserializerError do
      BasicDeserializer.belongs_to :explody
    end
  end
end
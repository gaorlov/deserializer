require 'minitest_helper'

class DeserializerErrorTest < Minitest::Test

  def test_error_contains_message
    begin 
      BasicDeserializer.has_one :lolnope
    rescue => e
      assert_equal "BasicDeserializer: has_one associations need a deserilaizer", e.message
    end
  end
end
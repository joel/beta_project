require 'test_helper'

require_relative '../../lib/ability_check'

class AbilityCheckTest < ActiveSupport::TestCase

  test "should check" do
    error = assert_raises(AbilityCheck::AbilityInconsistency) do
      AbilityCheck.new.check!
    end
    assert_equal "MISSING MAPPING FOR [Pages::Header]", error.message
  end

end

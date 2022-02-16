require 'test_helper'

class FooTest < ActiveSupport::TestCase

  def anonymous_model
    Class.new(ApplicationRecord) do
      def name
        "Anonymous"
      end
    end
  end

  def acts_as_foo_model
    Class.new(ApplicationRecord) do
      def name
        "Acts As Foo"
      end

      acts_as_foo
    end
  end

  test "should not acts as foo" do
    assert_not anonymous_model.acts_as_foo?
  end

  test "should acts as foo" do
    assert acts_as_foo_model.acts_as_foo?
  end

  test "descendants" do
    # binding.irb
    # ApplicationRecord.descendants
    # ApplicationRecord.descendants.map(&:name)
    # => ["Post", "Foo"]
  end
end

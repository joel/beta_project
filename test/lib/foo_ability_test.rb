require 'test_helper'

require_relative '../../lib/ability_model'

class FooTest < ActiveSupport::TestCase

  ActiveRecord::Schema.define do
    create_table :anonymous, force: true do |t|
      t.string :title
      t.timestamps
    end
    create_table :acts_as_foo_models, force: true do |t|
      t.string :name
      t.timestamps
    end
  end

  module Test

    class Anonymous < ApplicationRecord

      self.table_name = "anonymous"

    end

    class ActsAsFoo < ApplicationRecord

      self.table_name = "acts_as_foo_models"

      acts_as_foo

    end

  end

  test "should not acts as foo" do
    assert_not Test::Anonymous.acts_as_foo?
  end

  test "should acts as foo" do
    assert Test::ActsAsFoo.acts_as_foo?
  end

  test "list by ability" do
    assert_equal ["Scrapbook"], AbilityModel.ability(:acts_as_foo)
  end

end

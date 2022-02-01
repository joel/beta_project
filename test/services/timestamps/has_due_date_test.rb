# frozen_string_literal: true

require 'test_helper'

module Timestamps
  class HasDueDateTest < ActiveSupport::TestCase

    context "due_date and time" do

      should "not allow due_time to be set and due_date to be nil when created" do
        input = HasDueDateInput.new(date_attr: "31/12/2029", time_attr: "22:00", switch_attr: nil)
        item = HasDueDate.new(input)

        assert_equal "31/12/2029", item.due_date
        assert_equal "22:00", item.due_time
        assert_not item.all_day
      end
    end

  end
end

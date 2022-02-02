# frozen_string_literal: true

require 'test_helper'

module Timestamps
  class HasDueDateTest < ActiveSupport::TestCase

    context "due_date and time" do

      should "not allow due_time to be set and due_date to be nil when created" do
        input = HasDueDateInput.new(date_attr: "31/12/2029", time_attr: "22:00", switch_attr: nil)
        item  = HasDueDate.new(input: input).perform

        assert_nil item.errors

        assert_equal "31/12/2029", item.deadline.strftime("%d/%m/%Y")
        assert_equal "22:00", item.deadline.strftime("%H:%M")
      end
    end

    context "due_date without time" do

      should "set the due_time to the end of the day" do
        input = HasDueDateInput.new(date_attr: "31/12/2029", time_attr: nil, switch_attr: nil)
        item  = HasDueDate.new(input: input).perform

        assert_nil item.errors

        assert_equal "31/12/2029", item.deadline.strftime("%d/%m/%Y")
        assert_equal "23:59", item.deadline.strftime("%H:%M")
      end
    end

  end
end

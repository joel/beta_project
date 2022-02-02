# frozen_string_literal: true

require 'test_helper'

module Timestamps
  class HasDueDateInputTest < ActiveSupport::TestCase

    setup do
      @params = {
        date_attr: "31/12/2029",
        time_attr: nil,
        switch_attr: nil
      }
    end

    context "validations" do

      context "date_attr" do

        should "be valid" do
          assert HasDueDateInput.new(**@params).valid?
        end

        should "not be valid" do
          input = HasDueDateInput.new(**@params.merge(date_attr: "12/31/2029"))
          assert_not input.valid?
          assert_equal({:date_attr=>["bad format [12/31/2029] should be DD/MM/YYYY"]}, input.errors.messages)
        end

      end

      context "time_attr" do

        should "be valid" do
          assert HasDueDateInput.new(**@params.merge(time_attr: "15:00")).valid?
        end

        should "not be valid" do
          input = HasDueDateInput.new(**@params.merge(time_attr: "15:00", date_attr: nil))
          assert_not input.valid?
          assert_equal({:date_attr=>["is required if time is passed"]}, input.errors.messages)
        end

      end

    end

    context "deprecation" do
      context "switch_attr" do
        should "warn the deprecation and set the value" do
          assert_warn(StructuredWarnings::DeprecatedMethodWarning) do

            input = HasDueDateInput.new(**@params)

            assert_changes( -> { input.switch_attr }, "should set switch_attr value", from: nil, to: true) do
              input.switch_attr = true
            end

          end
        end
      end
    end

  end

end

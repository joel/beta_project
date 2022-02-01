# frozen_string_literal: true

require 'test_helper'

module Timestamps
  class HasDueDateInputTest < ActiveSupport::TestCase

    context "validations" do

      context "date_attr" do

        setup do
          @params = {
            date_attr: "31/12/2029",
            time_attr: nil,
            switch_attr: nil
          }
        end

        should "be valid" do
          assert HasDueDateInput.new(**@params).valid?
        end

        should "not be valid" do
          input = HasDueDateInput.new(**@params.merge(date_attr: "12/31/2029"))
          assert_not input.valid?
          assert_equal({:date_attr=>["bad format [12/31/2029] should be DD/MM/YYYY"]}, input.errors.messages)
        end

      end

    end

  end

end

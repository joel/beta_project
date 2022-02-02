# frozen_string_literal: true

require 'test_helper'

class StringTimeValidatorTest < ActiveSupport::TestCase

  class Validatable
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :time_attr

    validates_with StringTimeValidator
  end


  context "validations" do

    context "time_attr" do

      setup do
        @params = {
          time_attr: "15:30"
        }
      end

      should "be valid" do
        assert Validatable.new(@params).valid?
      end

      should "not be valid" do
        input = Validatable.new(@params.merge(time_attr: "8h"))
        assert_not input.valid?
        assert_equal({:time_attr=>["bad format [8h] should be HH:MM"]}, input.errors.messages)
      end

      should "be optional" do
        input = Validatable.new(@params.merge(time_attr: nil))
        assert input.valid?
      end

    end

  end

end

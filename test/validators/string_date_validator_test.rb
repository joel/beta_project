# frozen_string_literal: true

require 'test_helper'

class StringDateValidatorTest < ActiveSupport::TestCase

  class Validatable
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :date_attr

    validates_with StringDateValidator
  end


  context "validations" do

    context "date_attr" do

      setup do
        @params = {
          date_attr: "31/12/2029"
        }
      end

      should "be valid" do
        assert Validatable.new(@params).valid?
      end

      should "not be valid" do
        input = Validatable.new(@params.merge(date_attr: "12/31/2029"))
        assert_not input.valid?
        assert_equal({:date_attr=>["bad format [12/31/2029] should be DD/MM/YYYY"]}, input.errors.messages)
      end

    end

  end

end

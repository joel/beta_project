# frozen_string_literal: true

module Timestamps
  class HasDueDateInput < ::Input

    attr_accessor :date_attr, :time_attr, :switch_attr

    validates :date_attr, presence: true
    validates_with StringDateValidator

  end

end

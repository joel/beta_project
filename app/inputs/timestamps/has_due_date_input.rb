# frozen_string_literal: true

module Timestamps
  class HasDueDateInput < ::Input

    attr_accessor :date_attr, :time_attr
    attr_reader :switch_attr

    validates :date_attr, presence: true
    validates_with StringDateValidator

    def switch_attr=(value)
      warn StructuredWarnings::DeprecatedMethodWarning, "Set the flag all_day is deprecated, set [time_attr] to nil instead" unless value.blank?

      @switch_attr = value
    end

  end

end

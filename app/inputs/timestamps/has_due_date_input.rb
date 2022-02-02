# frozen_string_literal: true

module Timestamps
  class HasDueDateInput < ::Input

    attr_accessor :date_attr, :time_attr
    attr_reader :switch_attr

    validates_with StringDateValidator
    validates_with StringTimeValidator

    validate :date_attr_optional

    def switch_attr=(value)
      warn StructuredWarnings::DeprecatedMethodWarning, "Set the flag all_day is deprecated, set [time_attr] to nil instead" unless value.blank?

      @switch_attr = value
    end

    def proceedable?
      date_attr.present? || time_attr.present?
    end

    private

    def date_attr_optional
      if time_attr.present? && date_attr.blank?
        errors.add(:date_attr, "is required if time is passed")
      end
    end

  end

end

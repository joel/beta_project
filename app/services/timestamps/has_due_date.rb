# frozen_string_literal: true

module Timestamps
  class HasDueDate

    attr_reader :input, :deadline, :errors

    def initialize(input:)
      @input = input
    end

    def perform
      return self unless input.proceedable?

      if input.valid?
        unless input.time_attr
          deadline_str = "#{input.date_attr}"
        else
          deadline_str = "#{input.date_attr} #{input.time_attr}"
        end

        @deadline = Time.zone.parse(deadline_str) # Returns the TimeWithZone value

        @deadline = @deadline.change(hour: 23, min: 59, sec: 59) unless input.time_attr
      else
        @errors = input.errors
      end

      self
    end

  end
end

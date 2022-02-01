# frozen_string_literal: true

module Timestamps
  class HasDueDate

    attr_reader :errors

    def initialize(input)
      if input.valid?
        deadline_str = "#{input.date_attr} #{input.time_attr}"
        @deadline = Time.zone.parse(deadline_str) # Returns the TimeWithZone value
      else
        @errors = input.errors
      end
    end

    def due_date
      deadline.strftime("%d/%m/%Y")
    end

    def due_time
      deadline.strftime("%H:%M")
    end

    def all_day
      deadline.strftime("%H:%M") == "23:59"
    end
    alias all_day? all_day

    def valid?
      !@errors.present?
    end

    private

    attr_reader :deadline
  end
end

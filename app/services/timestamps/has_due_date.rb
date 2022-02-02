# frozen_string_literal: true

module Timestamps
  class HasDueDate

    attr_reader :errors, :deadline

    def initialize(input)
      return unless input.proceedable?

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
    end

    def due_date
      return unless deadline

      deadline.strftime("%d/%m/%Y")
    end

    def due_time
      return unless deadline

      deadline.strftime("%H:%M")
    end

    def all_day
      return unless deadline

      deadline.strftime("%H:%M") == "23:59"
    end
    alias all_day? all_day

    def valid?
      @errors.any?
    end

  end
end

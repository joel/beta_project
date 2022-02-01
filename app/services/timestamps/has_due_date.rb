# frozen_string_literal: true

module Timestamps
  class HasDueDate

    attr_reader :date_attr, :time_attr, :switch_attr

    # TODO: Extract that in inputs object
    # Assume for now valid inputs
    def initialize(date_attr:, time_attr:, switch_attr:)
      @date_attr   = date_attr
      @time_attr   = time_attr
      @switch_attr = switch_attr

      @deadline_str = "#{date_attr} #{time_attr}"
      @deadline = Time.zone.parse(@deadline_str) # Returns the TimeWithZone value
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

    private

    attr_reader :deadline
  end
end

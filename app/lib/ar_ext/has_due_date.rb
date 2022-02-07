# frozen_string_literal: true

module ArExt

  module HasDueDate

    module Scopes
      extend ActiveSupport::Concern

      included do
        scope :due_today, -> {
          current_time = Time.zone.now
          where("deadline BETWEEN ? AND ?", current_time.beginning_of_day, current_time.end_of_day)
        }
      end
    end

    module Validations
      extend ActiveSupport::Concern

      included do
        validate :validate_has_due_date
        after_validation :set_due_date
      end
    end

    module InstanceMethods
      extend ActiveSupport::Concern

      included do
        # ------------------------------------------------
        # -------------- P R E S E N T E R S -------------
        # ------------------------------------------------

        # date_attr: :due_date
        define_method(deadline_attributes[:date_attr]) do
          return if read_attribute(:deadline).blank?

          read_attribute(:deadline).strftime("%d/%m/%Y")
        end

        # time_attr: :due_time
        define_method(deadline_attributes[:time_attr]) do
          return if read_attribute(:deadline).blank?

          read_attribute(:deadline).strftime("%H:%M")
        end

        # switch_attr: :all_day
        define_method(deadline_attributes[:switch_attr]) do
          return if read_attribute(:deadline).blank?

          read_attribute(:deadline).strftime("%H:%M") == "23:59"
        end

        # switch_attr: :all_day?
        define_method("#{deadline_attributes[:switch_attr]}?") do
          public_send(deadline_attributes[:switch_attr])
        end

        # ------------------------------------------------
        # -------------- P R E S E N T E R S -------------
        # ------------------------------------------------

        # ************************************************

        # ------------------------------------------------
        # -------------- VIRTUAL ATTRIBUTES -------------
        # ------------------------------------------------

        %i[date_attr time_attr].each do |virtual_attribute|
          define_method("#{deadline_attributes[virtual_attribute]}=") do |value|
            instance_variable_set(:"@#{virtual_attribute}", value)
          end
        end

        define_method("#{deadline_attributes[:switch_attr]}=") do |value|
          warn StructuredWarnings::DeprecatedMethodWarning, "Set the flag #{deadline_attributes[:switch_attr]} is deprecated, set #{deadline_attributes[:time_attr]}_virtual = nil instead"

          public_send("#{deadline_attributes[:time_attr]}=", nil)
        end

        private

        %i[date_attr time_attr switch_attr].each do |virtual_attribute|
          define_method("_#{deadline_attributes[virtual_attribute]}") do
            instance_variable_get(:"@#{virtual_attribute}")
          end
        end

        # ------------------------------------------------
        # -------------- VIRTUAL ATTRIBUTES -------------
        # ------------------------------------------------

        def validate_has_due_date
          input = virtual_inputs
          self.errors.merge!(input.errors) unless input.valid?
        end

        def set_due_date
          input = virtual_inputs
          return unless input.valid?

          service = Timestamps::HasDueDate.new(input: input).perform
          return if service.deadline.nil? && deadline.present? # Do Not Override if Set

          write_attribute(:deadline, service.deadline)
        end

        def virtual_inputs
          Timestamps::HasDueDateInput.new(
            date_attr: send("_#{deadline_attributes[:date_attr]}"),
            time_attr: send("_#{deadline_attributes[:time_attr]}"),
            switch_attr: send("_#{deadline_attributes[:switch_attr]}"),
          )
        end

      end
    end

    module MacroMethods
      extend ActiveSupport::Concern
      include Scopes
      include Validations
      include InstanceMethods

      included do
        class_attribute :deadline_attributes

        attribute_names = opts.reverse_merge(
          date_attr: :due_date,
          time_attr: :due_time,
          switch_attr: :all_day
        )

        self.deadline_attributes = attribute_names
      end
    end

  end
end

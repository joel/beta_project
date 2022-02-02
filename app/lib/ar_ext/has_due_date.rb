# frozen_string_literal: true

module ArExt

  module HasDueDate

    module MacroMethods

      def has_due_date(opts = {})

        thread_cattr_accessor :deadline_attributes, instance_writer: false, instance_reader: true

        attribute_names = opts.reverse_merge(
          date_attr: :due_date,
          time_attr: :due_time,
          switch_attr: :all_day
        )

        self.deadline_attributes = attribute_names

        %w[Scopes].each do |mod_name|
          mod = "ArExt::HasDueDate::#{mod_name}".constantize
          include mod unless included_modules.include?(mod)
        end

        %w[Validations InstanceMethods].each do |mod_name|
          mod = "ArExt::HasDueDate::#{mod_name}".constantize
          include mod unless included_modules.include?(mod)
        end

      end
    end

    module Scopes
      def self.included(base)
        base.class_eval do
          scope :due_today, -> {
            current_time = Time.zone.now
            where("#{date_attr} BETWEEN ? AND ?", current_time.beginning_of_day, current_time.end_of_day)
          }
        end
      end
    end

    module Validations
      def self.included(base)
        base.class_eval do
          validate :validate_has_due_date
        end
      end
    end

    module InstanceMethods
      def self.included(base)
        base.class_eval do

          # ------------------------------------------------
          # -------------- P R E S E N T E R S -------------
          # ------------------------------------------------

          define_method(deadline_attributes[:date_attr]) do
            return if read_attribute(:deadline).blank?

            read_attribute(:deadline).strftime("%d/%m/%Y")
          end

          define_method(deadline_attributes[:time_attr]) do
            return if read_attribute(:deadline).blank?

            read_attribute(:deadline).strftime("%H:%M")
          end

          define_method(deadline_attributes[:switch_attr]) do
            return if read_attribute(:deadline).blank?

            read_attribute(:deadline).strftime("%H:%M") == "23:59"
          end

          # ------------------------------------------------
          # -------------- P R E S E N T E R S -------------
          # ------------------------------------------------



          # ------------------------------------------------
          # -------------- VIRTUAL ATTRIBUTES -------------
          # ------------------------------------------------

          attr_accessor :date_attr, :time_attr, :switch_attr

          # ------------------------------------------------
          # -------------- VIRTUAL ATTRIBUTES -------------
          # ------------------------------------------------

          private

          def validate_has_due_date
            input = Timestamps::HasDueDateInput.new(
              date_attr: date_attr,
              time_attr: time_attr,
              switch_attr: switch_attr,
            )

            self.errors.merge!(input.errors) unless input.valid?
          end

        end
      end
    end
  end
end

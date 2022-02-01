# frozen_string_literal: true

module ArExt

  module HasDueDate

    module MacroMethods

      def has_due_date(opts = {})

        thread_cattr_accessor :date_attr, instance_writer: false, instance_reader: true
        thread_cattr_accessor :time_attr, instance_writer: false, instance_reader: true
        thread_cattr_accessor :switch_attr, instance_writer: false, instance_reader: true

        attribute_names = opts.reverse_merge(
          date_attr: :due_date,
          time_attr: :due_time,
          switch_attr: :all_day
        )

        self.date_attr   = attribute_names[:date_attr]
        self.time_attr   = attribute_names[:time_attr]
        self.switch_attr = attribute_names[:switch_attr]

        %w[Scopes].each do |mod_name|
          mod = "ArExt::HasDueDate::#{mod_name}".constantize
          include mod unless included_modules.include?(mod)
        end

        %w[IncludedInstanceMethods].each do |mod_name|
          mod = "ArExt::HasDueDate::#{mod_name}".constantize
          include mod unless included_modules.include?(mod)
        end

        %w[PrependedInstanceMethods].each do |mod_name|
          mod = "ArExt::HasDueDate::#{mod_name}".constantize
          prepend mod unless included_modules.include?(mod)
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
          validates :"#{date_attr}", presence: true
        end
      end
    end

    module IncludedInstanceMethods
      def self.included(base)
        base.class_eval do

          define_method(time_attr) do
            return if read_attribute(date_attr).blank?

            read_attribute(date_attr).strftime("%H:%M")
          end

          # define_method(date_attr) do
          #   return if read_attribute(date_attr).blank?
          #
          #   read_attribute(date_attr).strftime("%d/%m/%Y")
          # end

        end
      end
    end

    module PrependedInstanceMethods
      def self.prepended(base)
        base.class_eval do

          def assign_attributes(new_attributes)
            attrs_with_string_keys = new_attributes.stringify_keys

            date_attr_value   = attrs_with_string_keys.delete(date_attr.to_s)
            time_attr_value   = attrs_with_string_keys.delete(time_attr.to_s)
            switch_attr_value = attrs_with_string_keys.delete(switch_attr.to_s)

            input = Timestamps::HasDueDateInput.new(
              date_attr: date_attr_value,
              time_attr: time_attr_value,
              switch_attr: switch_attr_value,
            )

            service = Timestamps::HasDueDate.new(input)

            super(
              attrs_with_string_keys.merge(
                "#{date_attr}" => service.deadline
              )
            )
          end

        end
      end

    end

  end
end

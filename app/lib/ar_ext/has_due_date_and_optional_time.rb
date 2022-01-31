# frozen_string_literal: true

module ArExt

  # Allows a model to have a due date attr or a due date with time attr.
  #
  # The switch attr flag (default: all_day) is used to record if the user has
  # set a due time for the model or not. If no due time attr is set the switch
  # flag is set to true and the time is set to 23:59. The user should not see
  # this time in the UI. If a time attr is set the switch flag will be set to
  # false.
  #
  # This allows us to treat the optional time part using the standard datetime
  # type and allows us to order the items easily.
  #
  # = Usage
  #
  # class ModelName
  #
  #   has_due_date_and_optional_time
  #     :time_attr => TIME_ATTR # default due_time
  #     :date_attr => DATE_ATTR # default due_date
  #     :switch_attr => SWITCH_ATTR # default all_day
  #
  # = Example
  #
  # The Post model uses has_due_date_and_optional_time.
  #
  # post = Post.last
  #
  # t = Post.create!(name: "Foo", due_date: "1/4/2019", due_time: "")
  # t.due_date
  # => Mon, 01 Apr 2019 23:59:59 BST +01:00
  # t.due_time
  # => nil
  # t.all_day?
  # => true
  #
  # t = Post.create!(name: "Foo", due_date: "1/4/2019", due_time: "7:30")

  # t.due_date
  # => Mon, 01 Apr 2019 07:30:00 BST +01:00
  # t.due_time
  # => "07:30"
  # t.all_day?
  # => false
  #
  # Post.create!(name: "Foo", due_date: "", due_time: "7:30")
  # => Raises: ActiveRecord::RecordInvalid (Validation failed: Due date Please enter a date)
  module HasDueDateAndOptionalTime

    module MacroMethods

      def has_due_date_and_optional_time(opts = {})
        # return if included_modules.include?(MacroMethods)

        class_attribute :date_attr, :time_attr, :switch_attr

        attribute_names = opts.reverse_merge(
          date_attr: :due_date,
          time_attr: :due_time,
          switch_attr: :all_day
        )

        self.date_attr   = attribute_names[:date_attr]
        self.time_attr   = attribute_names[:time_attr]
        self.switch_attr = attribute_names[:switch_attr]

        %w[Attributes Scopes Validations InstanceMethods].each do |mod_name|
          mod = "ArExt::HasDueDateAndOptionalTime::#{mod_name}".constantize

          # include mod unless included_modules.include?(mod)
          #
          # mod = mod_name.constantize

          puts("[#{mod}] => [#{included_modules.include?(mod)}]")

          include mod unless included_modules.include?(mod)
        end
      end

    end

    module Attributes

      def self.included(base)
        base.class_eval do

          puts("[Attributes] => [#{included_modules.include?(Attributes)}]")

          # return if included_modules.include?(Attributes)

          # puts("[#{mod}] => [#{included_modules.include?(mod)}]")

          attr_accessor time_attr

        end
      end

    end

    module Scopes

      def self.included(base)
        base.class_eval do

          puts("[Scopes] => [#{included_modules.include?(Scopes)}]")
          # return if included_modules.include?(Scopes)

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

          puts("[Attributes] => [#{included_modules.include?(Attributes)}]")
          # return if included_modules.include?(Validations)

          validate :"#{date_attr}_set_if_time_set"
          validate :"#{date_attr}_is_valid"

        end
      end

    end

    module InstanceMethods

      # Sets time on the date attr
      # If the date attr is not set write the time attr

      def self.included(base)
        base.class_eval do

          # binding.irb

          puts("[InstanceMethods] => [#{included_modules.include?(InstanceMethods)}]")
          # return if included_modules.include?(InstanceMethods)

          define_method(:"#{time_attr}=") do |time_string|
            parsed_time = validate_time(time_string)
            if parsed_time
              send(:"#{switch_attr}=", false)
              if send(date_attr)
                write_attribute(date_attr, send(date_attr).change(hour: parsed_time.hour, min: parsed_time.min))
              else
                instance_variable_set(:"@#{time_attr}", time_string)
              end
            elsif send(date_attr).blank?
              instance_variable_set(:"@#{time_attr}", time_string)
            else
              send(:"#{switch_attr}=", true)
              write_attribute(date_attr, send(date_attr).change(hour: 23, min: 59, sec: 59))
            end
          end

          # Return the time attr from the date attr if it is set
          # otherwise return the time attribute

          define_method(time_attr) do
            if send(date_attr).blank?
              instance_variable_get(:"@#{time_attr}")
            elsif !send(send(:switch_attr))
              send(date_attr).strftime("%R")
            end
          end

          # Virtual date attribute writer, handles logic for setting the attribute
          define_method(:"#{date_attr}=") do |date|
            if date.blank?
              date = nil
            elsif date.is_a?(String)
              parsed_date = validate_date(date)
              if parsed_date
                date = parsed_date
              else
                instance_variable_set(:"@#{date_attr}_invalid", true)
                return false
              end
            end
            write_attribute(date_attr, date)
          end

          # Ensure date attr is assigned first, as it's needed by the #due_time=
          define_method :"attributes=" do |attrs|
            attrs_with_string_keys = attrs.stringify_keys
            if attrs_with_string_keys.key?(date_attr.to_s)
              send(:"#{date_attr}=", attrs_with_string_keys.delete(date_attr.to_s))
            end

            super(attrs_with_string_keys)
          end

          private

          define_method(:"#{date_attr}_set_if_time_set") do
            if instance_variable_get(:"@#{time_attr}").present? && read_attribute(date_attr).blank?
              errors.add(date_attr, "Please enter a date")
            end
          end

          define_method(:"#{date_attr}_is_valid") do
            errors.add(date_attr, "must be a valid date") if instance_variable_get(:"@#{date_attr}_invalid")
          end

        end
      end

      private

      # Parse a date from a string (01/01/2014)
      # If valid return DateTime variable
      def validate_date(date = nil)
        validate_datetime(date)
      end

      def validate_time(time = nil)
        validate_datetime(time, "%H:%M")
      end

      def validate_datetime(datetime = nil, format = "%d/%m/%Y")
        return if datetime.blank?

        begin
          Time.zone.parse(datetime) if DateTime.strptime(datetime, format)
        rescue ArgumentError
          Rails.logger.error "Incorrect time: #{datetime.inspect} - #{format}"
          false
        end
      end

    end

  end
end

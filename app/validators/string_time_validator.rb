# frozen_string_literal: true

class StringTimeValidator < ActiveModel::Validator

  def validate(record)
    value = record.time_attr
    attribute = :time_attr

    unless value.is_a?(String)
      record.errors.add(attribute, "must be a String")
      return false
    end

    match = value.match(/^(?<hour>\d{1,2}):(?<minute>\d{1,2})/)

    unless match
      record.errors.add(attribute, "bad format [#{value}] should be HH:MM")
      return false
    end

    unless (0..24).include?(match[:hour].to_i)
      record.errors.add(attribute, "bad format [#{value}] should be HH:MM")
      return false
    end

    unless (0..59).include?(match[:minute].to_i)
      record.errors.add(attribute, "bad format [#{value}] should be HH:MM")
      return false
    end
  end

end

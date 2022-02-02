# frozen_string_literal: true

class StringDateValidator < ActiveModel::Validator

  def validate(record)
    value = record.date_attr
    attribute = :date_attr

    # Optional
    unless value
      return true
    end

    unless value.is_a?(String)
      record.errors.add(attribute, "must be a String")
      return false
    end

    match = value.match(/^(?<day>\d{1,2})\/(?<month>\d{1,2})\/(?<year>\d{4})/)

    unless match
      record.errors.add(attribute, "bad format [#{value}] should be DD/MM/YYYY")
      return false
    end

    unless (1..31).include?(match[:day].to_i)
      record.errors.add(attribute, "bad format [#{value}] should be DD/MM/YYYY")
      return false
    end

    unless (1..12).include?(match[:month].to_i)
      record.errors.add(attribute, "bad format [#{value}] should be DD/MM/YYYY")
      return false
    end
  end

end

# frozen_string_literal: true

module FooAbility

  module MacroMethods

    def acts_as_foo
      return if self.included_modules.include?(FooAbility::Predicates)

      include FooAbility::Predicates

    end

    def acts_as_foo?
      false
    end

  end

  module Predicates

    def self.included(base)

      base.class_eval do

        def self.acts_as_foo?
          true
        end

      end

    end

  end

end

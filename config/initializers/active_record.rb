require_relative '../../lib/foo_ability'
ApplicationRecord.extend FooAbility::MacroMethods

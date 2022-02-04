require_relative '../../lib/ar_ext/has_due_date_and_optional_time'
ActiveRecord::Base.extend ArExt::HasDueDateAndOptionalTime::MacroMethods

class Post < ApplicationRecord
  extend ArExt::HasDueDateAndOptionalTime::MacroMethods

  has_due_date_and_optional_time
end

class Task < ApplicationRecord
  extend ArExt::HasDueDate::MacroMethods

  has_due_date
end

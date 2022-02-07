class Task < ApplicationRecord
  extend ArExt::HasDueDate::Configure
  include ArExt::HasDueDate::InstanceMethods

end

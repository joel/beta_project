class AddDueDateToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :due_date, :datetime
  end
end

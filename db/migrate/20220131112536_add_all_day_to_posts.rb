class AddAllDayToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :all_day, :boolean, null: false, default: false
  end
end

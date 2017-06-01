class AddCachedToRaceDays < ActiveRecord::Migration[5.1]
  def change
    add_column :race_days, :cached, :boolean, default: false
  end
end

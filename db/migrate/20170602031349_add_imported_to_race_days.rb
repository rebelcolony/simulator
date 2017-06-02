class AddImportedToRaceDays < ActiveRecord::Migration[5.1]
  def change
    add_column :race_days, :imported, :boolean, default: false
  end
end

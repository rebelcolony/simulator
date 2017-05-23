class CreateSimulations < ActiveRecord::Migration[5.1]
  def change
    create_table "simulations", force: true do |t|
      t.integer  "race_day_id",   null: false
      t.float    "interval",      null: false
      t.float    "range_min",     null: false
      t.float    "range_max",     null: false
      t.integer  "market_type",   null: false
      t.string   "country",       null: false
      t.string   "rule",          null: false
      t.datetime "created_at",    null: false

      t.integer  "total"
      t.integer  "winners"
      t.float    "best_price"
      t.float    "return"
      t.float    "profit"
      t.float    "hit_rate"
    end

    add_index :simulations, :race_day_id
    add_index :simulations, :interval
    add_index :simulations, :range_min
    add_index :simulations, :range_max
    add_index :simulations, :market_type
    add_index :simulations, :country
    add_index :simulations, :rule
  end
end

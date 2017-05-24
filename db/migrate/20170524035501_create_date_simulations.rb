class CreateDateSimulations < ActiveRecord::Migration[5.1]
  def change
    create_table "date_simulations", force: true do |t|
      t.date     "since",       null: false
      t.date     "up_to",       null: false
      t.float    "interval",    null: false
      t.float    "range_min",   null: false
      t.float    "range_max",   null: false
      t.integer  "market_type", null: false
      t.string   "country",     null: false
      t.string   "rule",        null: false
      t.datetime "created_at",  null: false

      t.integer  "total"
      t.integer  "winners"
      t.float    "best_price"
      t.float    "return"
      t.float    "profit"
      t.float    "hit_rate"
    end

    add_index :date_simulations, :since
    add_index :date_simulations, :up_to
    add_index :date_simulations, :interval
    add_index :date_simulations, :range_min
    add_index :date_simulations, :range_max
    add_index :date_simulations, :market_type
    add_index :date_simulations, :country
    add_index :date_simulations, :rule
  end
end

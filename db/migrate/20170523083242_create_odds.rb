class CreateOdds < ActiveRecord::Migration[5.1]
  def change
    create_table "odds", force: true do |t|
      t.float    "value",         null: false
      t.integer  "market_type",   null: false
      t.integer  "runner_id",     null: false
      t.integer  "race_day_id",   null: false
      t.boolean  "won",           null: false
      t.integer  "country",       null: false
      t.datetime "race_start_at", null: false
      t.datetime "created_at",    null: false
    end

    add_index "odds", ["created_at"], name: "index_odds_on_created_at", using: :btree
    add_index "odds", ["race_start_at"], name: "index_odds_on_race_start_at", using: :btree
    add_index "odds", ["race_day_id"], name: "index_odds_on_race_day_id", using: :btree
    add_index "odds", ["market_type"], name: "index_odds_on_market_type", using: :btree
    add_index "odds", ["runner_id"], name: "index_odds_on_runner_id", using: :btree
    add_index "odds", ["country"], name: "index_odds_on_country", using: :btree
  end
end

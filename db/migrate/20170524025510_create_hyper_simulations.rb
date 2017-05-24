class CreateHyperSimulations < ActiveRecord::Migration[5.1]
  def change
    create_table :hyper_simulations do |t|
      t.string   "country",       null: false
      t.date     "since",         null: false, default: Date.new(2016, 6, 12)
      t.date     "up_to",         null: false, default: -> { 'NOW()' }
      t.integer  "range_min",     null: false, default: 1
      t.integer  "range_max",     null: false, default: 20
      t.float    "range_step",    null: false, default: 1.0
      t.float    "interval_min",  null: false, default: -0.3
      t.float    "interval_max",  null: false, default: 4.5
      t.integer  "market_type",   null: false, default: 1
      t.string   "rule",          null: false, default: 'lay'
      t.string   "metrics",       null: false, default: ['points', 'hit_rate', 'daily_strike_rate'], array: true
      t.datetime "created_at",    null: false
      t.text     "results"
    end
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170524035501) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "username", null: false
    t.string "encrypted_password", null: false
    t.string "encrypted_password_iv", null: false
    t.boolean "bet", default: false, null: false
    t.string "application_key"
  end

  create_table "bookies", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "url", null: false
    t.integer "easy_odds_ref"
    t.string "odds_checker_ref", limit: 2
  end

  create_table "date_simulations", force: :cascade do |t|
    t.date "since", null: false
    t.date "up_to", null: false
    t.float "interval", null: false
    t.float "range_min", null: false
    t.float "range_max", null: false
    t.integer "market_type", null: false
    t.integer "country", null: false
    t.string "rule", null: false
    t.datetime "created_at", null: false
    t.integer "total"
    t.integer "winners"
    t.float "best_price"
    t.float "return"
    t.float "profit"
    t.float "hit_rate"
    t.index ["country"], name: "index_date_simulations_on_country"
    t.index ["interval"], name: "index_date_simulations_on_interval"
    t.index ["market_type"], name: "index_date_simulations_on_market_type"
    t.index ["range_max"], name: "index_date_simulations_on_range_max"
    t.index ["range_min"], name: "index_date_simulations_on_range_min"
    t.index ["rule"], name: "index_date_simulations_on_rule"
    t.index ["since"], name: "index_date_simulations_on_since"
    t.index ["up_to"], name: "index_date_simulations_on_up_to"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "formulas", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "formula"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hyper_simulations", force: :cascade do |t|
    t.integer "country", null: false
    t.date "since", default: "2016-06-12", null: false
    t.date "up_to", default: -> { "now()" }, null: false
    t.integer "range_min", default: 1, null: false
    t.integer "range_max", default: 20, null: false
    t.float "range_step", default: 1.0, null: false
    t.float "interval_min", default: -0.3, null: false
    t.float "interval_max", default: 4.5, null: false
    t.integer "market_type", default: 1, null: false
    t.string "rule", default: "lay", null: false
    t.string "metrics", default: ["points", "hit_rate", "daily_strike_rate"], null: false, array: true
    t.datetime "created_at", null: false
    t.text "results"
  end

  create_table "markets", id: :serial, force: :cascade do |t|
    t.string "ref"
    t.integer "market_type_id", null: false
    t.integer "race_id", null: false
    t.integer "winners", default: [], array: true
  end

  create_table "odd_sets", id: :serial, force: :cascade do |t|
    t.text "values", null: false
    t.integer "market_id", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_odd_sets_on_created_at"
    t.index ["market_id"], name: "index_odds_on_market_id"
  end

  create_table "odds", force: :cascade do |t|
    t.float "value", null: false
    t.integer "market_type", null: false
    t.integer "runner_id", null: false
    t.integer "race_day_id", null: false
    t.boolean "won", null: false
    t.integer "country", null: false
    t.datetime "race_start_at", null: false
    t.datetime "created_at", null: false
    t.index ["country"], name: "index_odds_on_country"
    t.index ["created_at"], name: "index_odds_on_created_at"
    t.index ["market_type"], name: "index_odds_on_market_type"
    t.index ["race_day_id"], name: "index_odds_on_race_day_id"
    t.index ["race_start_at"], name: "index_odds_on_race_start_at"
    t.index ["runner_id"], name: "index_odds_on_runner_id"
  end

  create_table "race_days", id: :serial, force: :cascade do |t|
    t.date "date", null: false
  end

  create_table "races", id: :serial, force: :cascade do |t|
    t.integer "race_day_id"
    t.string "title"
    t.datetime "start_at"
    t.integer "venue_id"
    t.integer "ref"
    t.text "event_times"
    t.integer "event_id"
    t.index ["venue_id"], name: "index_races_on_venue_id"
  end

  create_table "runners", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "cloth"
    t.integer "runner_id"
    t.integer "race_id"
    t.boolean "removed", default: false, null: false
    t.index ["race_id"], name: "index_runners_on_race_id"
  end

  create_table "selections", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.boolean "won"
    t.boolean "order_placed", default: false, null: false
    t.integer "runner_id", null: false
    t.float "best_price", null: false
    t.float "return"
    t.float "profit"
    t.float "real"
    t.datetime "created_at"
    t.integer "account_id", null: false
    t.integer "market_id"
    t.float "price_asked"
    t.float "price_matched"
    t.float "commission"
    t.integer "formula_id"
    t.index ["won"], name: "index_selections_on_won"
  end

  create_table "simulations", force: :cascade do |t|
    t.integer "race_day_id", null: false
    t.float "interval", null: false
    t.float "range_min", null: false
    t.float "range_max", null: false
    t.integer "market_type", null: false
    t.integer "country", null: false
    t.string "rule", null: false
    t.datetime "created_at", null: false
    t.text "selections"
    t.integer "total"
    t.integer "winners"
    t.float "best_price"
    t.float "return"
    t.float "profit"
    t.float "hit_rate"
    t.index ["country"], name: "index_simulations_on_country"
    t.index ["interval"], name: "index_simulations_on_interval"
    t.index ["market_type"], name: "index_simulations_on_market_type"
    t.index ["race_day_id"], name: "index_simulations_on_race_day_id"
    t.index ["range_max"], name: "index_simulations_on_range_max"
    t.index ["range_min"], name: "index_simulations_on_range_min"
    t.index ["rule"], name: "index_simulations_on_rule"
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "formula_id", null: false
    t.integer "stake"
    t.boolean "active", default: true, null: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "venues", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "country", limit: 2
  end

end

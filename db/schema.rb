# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_10_170008) do
  create_table "study_sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "actual_duration"
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.integer "duration", null: false
    t.datetime "end_time"
    t.integer "focus_rating"
    t.text "notes"
    t.datetime "start_time", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_study_sessions_on_user_id"
  end

  create_table "tasks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "due_date"
    t.string "priority"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "experience_points"
    t.date "last_study_date"
    t.integer "level"
    t.string "name"
    t.string "password_digest"
    t.integer "pet_energy"
    t.string "pet_mood"
    t.string "pet_name"
    t.string "pet_type"
    t.integer "streak_days"
    t.integer "total_study_time"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "study_sessions", "users"
  add_foreign_key "tasks", "users"
end

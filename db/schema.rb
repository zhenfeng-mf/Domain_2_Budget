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

ActiveRecord::Schema[8.1].define(version: 2026_09_09_053850) do
  create_table "budgets", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "approved_total", default: 0, null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.date "year_month", null: false
    t.index ["category_id"], name: "index_budgets_on_category_id"
    t.index ["team_id", "year_month", "category_id"], name: "idx_budgets_unique_team_month_category", unique: true
    t.index ["team_id"], name: "index_budgets_on_team_id"
    t.check_constraint "`amount` >= 0", name: "chk_budgets_amount_non_negative"
    t.check_constraint "`approved_total` <= `amount`", name: "chk_budgets_approved_total_within_amount"
    t.check_constraint "`approved_total` >= 0", name: "chk_budgets_approved_total_non_negative"
    t.check_constraint "dayofmonth(`year_month`) = 1", name: "chk_budgets_year_month_first_of_month"
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "expenses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "amount", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "decided_at"
    t.bigint "decided_by_id"
    t.string "purpose", null: false
    t.integer "status", default: 0, null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.date "used_on", null: false
    t.bigint "user_id", null: false
    t.index ["category_id", "used_on", "status"], name: "index_expenses_on_category_id_and_used_on_and_status"
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["decided_by_id"], name: "index_expenses_on_decided_by_id"
    t.index ["user_id", "status"], name: "index_expenses_on_user_id_and_status"
    t.index ["user_id"], name: "index_expenses_on_user_id"
    t.check_constraint "`amount` >= 1", name: "chk_expenses_amount_at_least_1_yen"
    t.check_constraint "`status` between 0 and 3", name: "chk_expenses_status_in_enum"
    t.check_constraint "char_length(`purpose`) >= 1", name: "chk_expenses_purpose_present"
  end

  create_table "teams", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "approver_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_teams_on_approver_id"
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["team_id"], name: "index_users_on_team_id"
    t.check_constraint "`role` between 0 and 1", name: "chk_users_role_in_enum"
  end

  add_foreign_key "budgets", "categories"
  add_foreign_key "budgets", "teams"
  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "users"
  add_foreign_key "expenses", "users", column: "decided_by_id"
  add_foreign_key "teams", "users", column: "approver_id"
  add_foreign_key "users", "teams"
end

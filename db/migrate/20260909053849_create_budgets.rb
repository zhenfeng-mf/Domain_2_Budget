class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.references :team,     null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.date    :year_month,     null: false  # always the 1st of the month (D-08)
      t.integer :amount,         null: false  # integer yen (D-02)
      t.integer :approved_total, null: false, default: 0  # D-04
      t.timestamps
    end

    # I-02 — one budget per (team, month, category)
    add_index :budgets, %i[team_id year_month category_id],
              unique: true, name: "idx_budgets_unique_team_month_category"

    # I-04 — budget is never negative and never below what is already approved
    add_check_constraint :budgets, "amount >= 0",
                         name: "chk_budgets_amount_non_negative"
    add_check_constraint :budgets, "approved_total >= 0",
                         name: "chk_budgets_approved_total_non_negative"
    # I-01 — the whole point of D-04: the DB itself refuses to be overspent
    add_check_constraint :budgets, "approved_total <= amount",
                         name: "chk_budgets_approved_total_within_amount"
    # D-08 — a month bucket can only ever be the 1st; DAYOFMONTH is deterministic,
    # so MySQL accepts it inside a CHECK
    add_check_constraint :budgets, "DAY(`year_month`) = 1",
                         name: "chk_budgets_year_month_first_of_month"
  end
end

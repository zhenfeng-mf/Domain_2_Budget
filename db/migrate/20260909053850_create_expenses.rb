class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :user,     null: false, foreign_key: true  # I-06
      t.references :category, null: false, foreign_key: true
      t.date    :used_on, null: false          # 利用日 is a calendar day (D-03)
      t.integer :amount,  null: false          # integer yen (D-02)
      t.string  :purpose, null: false, limit: 255
      t.integer :status,  null: false, default: 0  # 0 下書き 1 申請済み 2 承認済み 3 却下
      t.datetime :submitted_at
      t.datetime :decided_at
      t.references :decided_by, null: true, foreign_key: { to_table: :users }
      t.timestamps
    end

    # I-03 — ≥ ¥1, enforced by the database, not only by numericality
    add_check_constraint :expenses, "amount >= 1",
                         name: "chk_expenses_amount_at_least_1_yen"
    # I-05 — no status outside the enum can ever be written
    add_check_constraint :expenses, "status BETWEEN 0 AND 3",
                         name: "chk_expenses_status_in_enum"
    add_check_constraint :expenses, "CHAR_LENGTH(purpose) >= 1",
                         name: "chk_expenses_purpose_present"

    add_index :expenses, %i[user_id status]                # 自分の申請一覧
    add_index :expenses, %i[category_id used_on status]     # 承認キュー・月次集計
  end
end

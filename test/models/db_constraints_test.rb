require "test_helper"

# Every test here writes THROUGH the validations on purpose.
class DbConstraintsTest < ActiveSupport::TestCase
  # I-02 — unique index on (team_id, year_month, category_id)
  test "DB rejects a duplicate budget for the same team, month and category" do
    b = budgets(:current_travel)
    assert_raises ActiveRecord::RecordNotUnique do
      Budget.insert!({
        team_id: b.team_id, category_id: b.category_id, year_month: b.year_month,
        amount: 1, approved_total: 0,
        created_at: Time.current, updated_at: Time.current
      })
    end
  end

  # I-01 — chk_budgets_approved_total_within_amount
  test "DB rejects an approved_total above the budget amount" do
    b = budgets(:current_travel)
    error = assert_raises ActiveRecord::StatementInvalid do
      b.update_columns(approved_total: b.amount + 1)
    end
    assert_match "chk_budgets_approved_total_within_amount", error.message
  end

  # I-04 — lowering the cap under what is already approved
  test "DB rejects lowering a budget amount below its approved_total" do
    b = budgets(:current_travel) # approved_total 30_000
    assert_raises ActiveRecord::StatementInvalid do
      b.update_columns(amount: b.approved_total - 1)
    end
  end

  # I-04 — chk_budgets_amount_non_negative
  test "DB rejects a negative budget amount" do
    assert_raises ActiveRecord::StatementInvalid do
      budgets(:next_books).update_columns(amount: -1)
    end
  end

  # I-03 — chk_expenses_amount_at_least_1_yen
  test "DB rejects an expense amount of 0 yen" do
    error = assert_raises ActiveRecord::StatementInvalid do
      expenses(:taro_draft).update_columns(amount: 0)
    end
    assert_match "chk_expenses_amount_at_least_1_yen", error.message
  end

  test "DB rejects a negative expense amount" do
    assert_raises ActiveRecord::StatementInvalid do
      expenses(:taro_draft).update_columns(amount: -500)
    end
  end

  # I-05 — chk_expenses_status_in_enum
  test "DB rejects a status outside the state machine" do
    assert_raises ActiveRecord::StatementInvalid do
      expenses(:taro_draft).update_columns(status: 9)
    end
  end

  # I-06 — ownership can never be lost
  test "DB rejects an expense with no owner" do
    assert_raises ActiveRecord::NotNullViolation do
      expenses(:taro_draft).update_columns(user_id: nil)
    end
  end

  test "DB rejects an expense owned by a non-existent user" do
    assert_raises ActiveRecord::InvalidForeignKey do
      expenses(:taro_draft).update_columns(user_id: 999_999_999)
    end
  end

  # D-08 — a month bucket is always the 1st
  test "DB rejects a mid-month year_month" do
    assert_raises ActiveRecord::StatementInvalid do
      budgets(:next_books).update_columns(year_month: Time.zone.today.next_month.change(day: 15))
    end
  end
end

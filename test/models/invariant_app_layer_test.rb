# test/models/invariant_app_layer_test.rb
require "test_helper"

# The three invariants MySQL cannot express, and the two rules that changed
# from the spec.
class InvariantAppLayerTest < ActiveSupport::TestCase
  # I-08 — 利用日 is immutable once the expense leaves 下書き
  test "used_on can move while the expense is a draft" do
    e = expenses(:taro_draft)
    assert e.update(used_on: Time.zone.today - 3)
  end

  test "used_on cannot be changed once submitted" do
    e = expenses(:taro_submitted)
    assert_not e.update(used_on: Time.zone.today - 40)
    assert_includes e.errors[:used_on].join, "申請後"
  end

  # I-09 — budgets are adjustable for future months only
  test "a future month budget can be adjusted" do
    assert budgets(:next_books).update(amount: 60_000)
  end

  test "the current month budget cannot be adjusted" do
    assert_not budgets(:current_travel).update(amount: 200_000)
  end

  test "a past month budget cannot be created" do
    b = Budget.new(team: teams(:alpha), category: categories(:books),
                   year_month: MonthBucket.current - 1.month, amount: 1_000)
    assert_not b.valid?
  end

  # I-10 / A-03 — no submission without a matching budget
  test "an expense cannot be submitted when no budget exists for its month and category" do
    e = Expense.new(user: users(:taro), category: categories(:books),
                    used_on: Time.zone.today, amount: 1_000,
                    purpose: "予算のない月", status: :submitted)
    assert_not e.valid?
    assert_match "予算が未設定", e.errors.full_messages.join
  end

  test "changing the category of a submitted expense re-checks the budget" do
    e = expenses(:taro_submitted)
    assert_not e.update(category: categories(:books)) # no current-month books budget
  end

  # I-11 — terminal states protect the counter
  test "an approved expense cannot be edited" do
    e = expenses(:taro_submitted)
    ApproveExpense.call(expense_id: e.id, approver: users(:hanako))
    assert_not e.reload.update(amount: 1)
  end

  # A-04
  test "an approver cannot approve their own expense" do
    own = Expense.create!(user: users(:hanako), category: categories(:travel),
                          used_on: Time.zone.today, amount: 1_000,
                          purpose: "自分の申請", status: :submitted,
                          submitted_at: Time.current)
    assert_raises ApproveExpense::Refused do
      ApproveExpense.call(expense_id: own.id, approver: users(:hanako))
    end
  end

  # I-05 — approve twice
  test "approve cannot run twice on the same request" do
    e = expenses(:taro_submitted)
    ApproveExpense.call(expense_id: e.id, approver: users(:hanako))
    assert_raises ApproveExpense::Refused do
      ApproveExpense.call(expense_id: e.id, approver: users(:hanako))
    end
  end

  # I-01 happy path + counter correctness
  test "approving increases approved_total and shrinks remaining" do
    budget = budgets(:current_travel)
    assert_difference -> { budget.reload.approved_total }, 5_000 do
      ApproveExpense.call(expense_id: expenses(:taro_submitted).id, approver: users(:hanako))
    end
    assert_equal budget.approved_total, budget.approved_sum, "counter must match the SUM (D-04)"
  end

  # I-01 refusal path
  test "an approval that would exceed the budget is refused" do
    budget = budgets(:current_travel) # 100_000 cap, 30_000 used
    big = Expense.create!(user: users(:jiro), category: categories(:travel),
                          used_on: Time.zone.today, amount: 80_000,
                          purpose: "高額", status: :submitted, submitted_at: Time.current)
    assert_raises ApproveExpense::Refused do
      ApproveExpense.call(expense_id: big.id, approver: users(:hanako))
    end
    assert_equal 30_000, budget.reload.approved_total
  end

  # I-07 — one bucketing method, and it uses the app timezone
  test "an expense is charged to the month of its used_on" do
    e = expenses(:taro_draft)
    e.used_on = Date.new(2026, 3, 31)
    assert_equal Date.new(2026, 3, 1), e.year_month
  end
end

require "test_helper"

class DecisionAuthorizationTest < ActiveSupport::TestCase
  setup do
    @other_approver = User.create!(name: "Other approver", email: "other-approver@example.com",
                                   password: "password", role: :approver)
    @other_team = Team.create!(name: "Other team", approver: @other_approver)
    @other_member = User.create!(name: "Other member", email: "other-member@example.com",
                                 password: "password", role: :member, team: @other_team)
    @other_budget = Budget.create!(team: @other_team, category: categories(:travel),
                                   year_month: MonthBucket.current, amount: 10_000)
  end

  test "unassigned approver cannot approve another team's request" do
    expense = expenses(:taro_submitted)
    budget = budgets(:current_travel)

    assert_raises ApproveExpense::Refused do
      ApproveExpense.call(expense_id: expense.id, approver: @other_approver)
    end
    assert expense.reload.submitted?
    assert_equal 30_000, budget.reload.approved_total
  end

  test "unassigned approver cannot reject another team's request" do
    expense = expenses(:taro_submitted)

    assert_raises RejectExpense::Refused do
      RejectExpense.call(expense_id: expense.id, approver: @other_approver)
    end
    assert expense.reload.submitted?
  end

  test "one approver can approve a request from a second assigned team" do
    @other_team.update!(approver: users(:hanako))
    expense = other_team_request

    ApproveExpense.call(expense_id: expense.id, approver: users(:hanako))

    assert expense.reload.approved?
    assert_equal 1_000, @other_budget.reload.approved_total
    assert_equal 2, users(:hanako).approving_teams.count
  end

  test "one approver can reject a request from a second assigned team" do
    @other_team.update!(approver: users(:hanako))
    expense = other_team_request

    RejectExpense.call(expense_id: expense.id, approver: users(:hanako))

    assert expense.reload.rejected?
    assert_equal 0, @other_budget.reload.approved_total
  end

  test "a member cannot decide a request" do
    assert_raises ApproveExpense::Refused do
      ApproveExpense.call(expense_id: expenses(:taro_submitted).id, approver: users(:jiro))
    end
    assert_raises RejectExpense::Refused do
      RejectExpense.call(expense_id: expenses(:taro_submitted).id, approver: users(:jiro))
    end
  end

  private

  def other_team_request
    Expense.create!(user: @other_member, category: categories(:travel),
                    used_on: Time.zone.today, amount: 1_000,
                    purpose: "Other team request", status: :submitted,
                    submitted_at: Time.current)
  end
end

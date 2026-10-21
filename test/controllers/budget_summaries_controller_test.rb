require "test_helper"

class BudgetSummariesTest < ActionDispatch::IntegrationTest
  test "member sees only own team's read-only budget summary" do
    other_approver = User.create!(name: "Other Approver", email: "other.approver@example.com",
                                  password: "password", role: :approver)
    other_team = Team.create!(name: "Other Team", approver: other_approver)
    Budget.create!(team: other_team, category: categories(:travel),
                   year_month: MonthBucket.current, amount: 987_654)

    post login_path, params: { email: users(:taro).email, password: "password" }
    get budget_summary_path

    assert_response :success
    assert_select "tbody tr", count: 2
    assert_includes response.body, teams(:alpha).name
    assert_includes response.body, "100,000"
    assert_includes response.body, "30,000"
    assert_includes response.body, "70,000"
    assert_not_includes response.body, "Other Team"
    assert_select "a[href^='/budgets']", count: 0
  end

  test "approver sees all assigned teams and no foreign team's budgets" do
    own_second_team = Team.create!(name: "Second Team", approver: users(:hanako))
    Budget.create!(team: own_second_team, category: categories(:travel),
                   year_month: MonthBucket.current, amount: 40_000)
    other_approver = User.create!(name: "Other Approver", email: "other.approver@example.com",
                                  password: "password", role: :approver)
    other_team = Team.create!(name: "Other Team", approver: other_approver)
    Budget.create!(team: other_team, category: categories(:travel),
                   year_month: MonthBucket.current, amount: 987_654)

    post login_path, params: { email: users(:hanako).email, password: "password" }
    get budget_summary_path

    assert_response :success
    assert_select "tbody tr", count: 3
    assert_includes response.body, teams(:alpha).name
    assert_includes response.body, own_second_team.name
    assert_not_includes response.body, other_team.name
    assert_select "a[href^='/budgets']", count: 0
  end

  test "anonymous visitor is redirected to login" do
    get budget_summary_path

    assert_redirected_to login_path
  end
end

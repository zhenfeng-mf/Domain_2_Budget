require "test_helper"

class BudgetsTest < ActionDispatch::IntegrationTest
  test "approver lists budgets only for assigned teams" do
    other_approver = User.create!(name: "Other Approver", email: "other.approver@example.com",
                                  password: "password", role: :approver)
    other_team = Team.create!(name: "Other Team", approver: other_approver)
    Budget.create!(team: other_team, category: categories(:travel),
                   year_month: MonthBucket.current, amount: 987_654)

    post login_path, params: { email: users(:hanako).email, password: "password" }
    get budgets_path

    assert_response :success
    assert_select "th", text: "予算額"
    assert_select "th", text: "承認済み"
    assert_select "th", text: "残額"
    assert_select "tbody tr", count: 2
    assert_includes response.body, teams(:alpha).name
    assert_includes response.body, categories(:travel).name
    assert_includes response.body, MonthBucket.label(budgets(:current_travel).year_month)
    assert_includes response.body, "70,000"
    assert_not_includes response.body, "Other Team"
    assert_not_includes response.body, "987,654"
  end

  test "member cannot see the approver budget list" do
    post login_path, params: { email: users(:taro).email, password: "password" }
    get budgets_path

    assert_response :forbidden
    assert_includes response.body, "承認者のみ"
  end

  test "assigned approver creates a budget with server-owned counter" do
    post login_path, params: { email: users(:hanako).email, password: "password" }
    get new_budget_path
    assert_response :success
    assert_select "select[name='budget[team_id]'] option", text: teams(:alpha).name

    assert_difference "Budget.count", 1 do
      post budgets_path, params: { budget: {
        team_id: teams(:alpha).id, category_id: categories(:travel).id,
        year_month: MonthBucket.current.next_month.strftime("%Y-%m"),
        amount: 20_000, approved_total: 19_000
      } }
    end

    created = Budget.order(:id).last
    assert_redirected_to budgets_path
    assert_equal MonthBucket.current.next_month, created.year_month
    assert_equal 20_000, created.amount
    assert_equal 0, created.approved_total
  end

  test "duplicate budget shows a validation error" do
    post login_path, params: { email: users(:hanako).email, password: "password" }

    assert_no_difference "Budget.count" do
      post budgets_path, params: { budget: {
        team_id: teams(:alpha).id, category_id: categories(:books).id,
        year_month: budgets(:next_books).year_month.strftime("%Y-%m"), amount: 20_000
      } }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert'] li", minimum: 1
  end

  test "member and unassigned approver cannot create budgets" do
    other_approver = User.create!(name: "Other Approver", email: "other.approver@example.com",
                                  password: "password", role: :approver)
    other_team = Team.create!(name: "Other Team", approver: other_approver)
    attributes = { team_id: other_team.id, category_id: categories(:travel).id,
                   year_month: MonthBucket.current.next_month.strftime("%Y-%m"), amount: 20_000 }

    post login_path, params: { email: users(:hanako).email, password: "password" }
    assert_no_difference "Budget.count" do
      post budgets_path, params: { budget: attributes }
    end
    assert_response :forbidden

    delete logout_path
    post login_path, params: { email: users(:taro).email, password: "password" }
    get new_budget_path
    assert_response :forbidden
    assert_includes response.body, "承認者のみ"
    assert_no_difference "Budget.count" do
      post budgets_path, params: { budget: attributes.merge(team_id: teams(:alpha).id) }
    end
    assert_response :forbidden
  end

  test "assigned approver changes only a future budget amount" do
    post login_path, params: { email: users(:hanako).email, password: "password" }
    budget = budgets(:next_books)

    get edit_budget_path(budget)
    assert_response :success

    patch budget_path(budget), params: { budget: {
      amount: 60_000, team_id: 999_999_999, approved_total: 40_000,
      category_id: categories(:travel).id, year_month: MonthBucket.current.to_s
    } }

    assert_redirected_to budgets_path
    assert_equal 60_000, budget.reload.amount
    assert_equal 0, budget.approved_total
    assert_equal categories(:books), budget.category
    assert_equal MonthBucket.current.next_month, budget.year_month
  end

  test "current month budget cannot be edited" do
    post login_path, params: { email: users(:hanako).email, password: "password" }
    budget = budgets(:current_travel)

    get edit_budget_path(budget)
    assert_redirected_to budgets_path
    patch budget_path(budget), params: { budget: { amount: 200_000 } }
    assert_redirected_to budgets_path
    assert_equal 100_000, budget.reload.amount
  end

  test "future budget cannot be reduced below approved use" do
    budget = Budget.create!(team: teams(:alpha), category: categories(:travel),
                            year_month: MonthBucket.current.next_month,
                            amount: 10_000, approved_total: 5_000)
    post login_path, params: { email: users(:hanako).email, password: "password" }

    patch budget_path(budget), params: { budget: { amount: 4_999 } }

    assert_response :unprocessable_entity
    assert_select "[role='alert'] li", text: /承認済み合計/
    assert_equal 10_000, budget.reload.amount
  end

  test "member and foreign approver cannot edit an assigned budget" do
    budget = budgets(:next_books)
    other_approver = User.create!(name: "Other Approver", email: "other.approver@example.com",
                                  password: "password", role: :approver)
    post login_path, params: { email: other_approver.email, password: "password" }
    get edit_budget_path(budget)
    assert_response :not_found
    patch budget_path(budget), params: { budget: { amount: 60_000 } }
    assert_response :not_found

    delete logout_path
    post login_path, params: { email: users(:taro).email, password: "password" }
    get edit_budget_path(budget)
    assert_response :forbidden
    patch budget_path(budget), params: { budget: { amount: 60_000 } }
    assert_response :forbidden
    assert_equal 50_000, budget.reload.amount
  end
end

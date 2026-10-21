require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "member sees only own requests" do
    post login_path, params: { email: users(:taro).email, password: "password" }
    get root_path

    assert_response :success
    assert_select "h2", text: "My requests"
    assert_includes response.body, expenses(:taro_draft).purpose
    assert_select "h2", text: "Pending requests", count: 0
  end

  test "approver sees assigned teams and their pending requests" do
    other_approver = User.create!(name: "Other Approver", email: "other.approver@example.com",
                                  password: "password", role: :approver)
    other_team = Team.create!(name: "Other Team", approver: other_approver)
    Budget.create!(team: other_team, category: categories(:travel),
                   year_month: MonthBucket.current, amount: 10_000)
    other_member = User.create!(name: "Other Member", email: "other.member@example.com",
                                password: "password", role: :member, team: other_team)
    Expense.create!(user: other_member, category: categories(:travel), used_on: Time.zone.today,
                    amount: 1_000, purpose: "Foreign pending request", status: :submitted)

    post login_path, params: { email: users(:hanako).email, password: "password" }
    get root_path

    assert_response :success
    assert_select "h2", text: "Budgets"
    assert_select "h2", text: "Pending requests"
    assert_includes response.body, teams(:alpha).name
    assert_includes response.body, expenses(:taro_submitted).purpose
    assert_not_includes response.body, "Foreign pending request"
    assert_select "h2", text: "My requests", count: 0
  end
end

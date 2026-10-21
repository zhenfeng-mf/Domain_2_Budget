require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "member needs a team" do
    user = User.new(name: "Member", email: "member-no-team@example.com",
                    password: "password", role: :member)
    assert_not user.valid?
    assert_includes user.errors[:team].join, "blank"
  end

  test "approver cannot belong to a team" do
    user = User.new(name: "Approver", email: "approver-with-team@example.com",
                    password: "password", role: :approver, team: teams(:alpha))
    assert_not user.valid?
    assert user.errors[:team].any?
  end

  test "approver can be assigned to multiple teams" do
    team = Team.create!(name: "Another team", approver: users(:hanako))
    assert_includes users(:hanako).approving_teams, team
    assert_equal 2, users(:hanako).approving_teams.count
  end
end

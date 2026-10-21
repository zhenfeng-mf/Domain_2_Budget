require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "team needs an approver" do
    team = Team.new(name: "No approver")
    assert_not team.valid?
    assert team.errors[:approver].any?
  end

  test "team approver must have the approver role" do
    team = Team.new(name: "Member assigned", approver: users(:taro))
    assert_not team.valid?
    assert team.errors[:approver].any?
  end
end

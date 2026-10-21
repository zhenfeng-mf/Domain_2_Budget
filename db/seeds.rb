# Minimal accounts and categories for the first browser flow. Passwords are set
# only when an account is created, so rerunning seeds does not reset them.
demo_password = if Rails.env.production?
  ENV.fetch("DEMO_PASSWORD")
else
  ENV.fetch("DEMO_PASSWORD", "demo-password-123")
end

ApplicationRecord.transaction do
  approver = User.find_or_create_by!(email: "approver@example.com") do |user|
    user.name = "Demo Approver"
    user.password = demo_password
    user.role = :approver
  end
  raise "Demo approver account has the wrong role or team" unless approver.approver? && approver.team_id.nil?

  team = Team.find_or_create_by!(name: "Demo Team") do |record|
    record.approver = approver
  end
  raise "Demo Team has a different approver" unless team.approver_id == approver.id

  member = User.find_or_create_by!(email: "member@example.com") do |user|
    user.name = "Demo Member"
    user.password = demo_password
    user.role = :member
    user.team = team
  end
  raise "Demo member account has the wrong role or team" unless member.member? && member.team_id == team.id

  ["交通費", "書籍費"].each do |name|
    Category.find_or_create_by!(name: name)
  end
end

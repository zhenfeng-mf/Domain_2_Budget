class SeparateMemberAndApproverRoles < ActiveRecord::Migration[8.1]
  def up
    if select_value("SELECT COUNT(*) FROM expenses INNER JOIN users ON users.id = expenses.user_id WHERE users.role = 1").to_i.positive?
      raise ActiveRecord::IrreversibleMigration, "Move or resolve approver-owned expenses before separating roles"
    end
    if select_value("SELECT COUNT(*) FROM teams WHERE approver_id IS NULL").to_i.positive?
      raise ActiveRecord::IrreversibleMigration, "Assign an approver to every team before separating roles"
    end

    change_column_null :users, :team_id, true
    execute "UPDATE users SET team_id = NULL WHERE role = 1"
    add_check_constraint :users,
                         "(role = 0 AND team_id IS NOT NULL) OR (role = 1 AND team_id IS NULL)",
                         name: "chk_users_team_matches_role"
    change_column_null :teams, :approver_id, false
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Approvers no longer have a team_id to restore"
  end
end

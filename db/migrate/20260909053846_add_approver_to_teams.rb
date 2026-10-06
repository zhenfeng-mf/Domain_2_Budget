class AddApproverToTeams < ActiveRecord::Migration[8.1]
  def change
    # Deliberately nullable: users.team_id is NOT NULL, so a NOT NULL approver_id
    # would make the first insert of either table impossible, and MySQL has no
    # deferrable constraints. Presence is enforced in Team (on: :update) and by
    # Budget refusing a team with no approver. See D-10.
    add_reference :teams, :approver, null: true,
                  foreign_key: { to_table: :users }
  end
end

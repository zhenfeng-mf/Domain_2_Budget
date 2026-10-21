class AllowUsersWithoutTeam < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :team_id, true
  end
end

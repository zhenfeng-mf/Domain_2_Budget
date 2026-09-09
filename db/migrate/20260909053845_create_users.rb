class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string  :name,            null: false
      t.string  :email,           null: false
      t.string  :password_digest, null: false
      t.integer :role,            null: false, default: 0  # 0 member / 1 approver
      t.references :team, null: false, foreign_key: true    # I-06 ownership chain
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_check_constraint :users, "role BETWEEN 0 AND 1", name: "chk_users_role_in_enum"
  end
end

class ChangeRolesUsersSchema < ActiveRecord::Migration
  def self.up
    drop_table 'roles_users'

    create_table "roles_users", :id => false, :force => true do |t|
      t.integer  "user_id"
      t.integer  "role_id"

      t.timestamps
    end
  end

  def self.down
    drop_table 'roles_users'
  end
end

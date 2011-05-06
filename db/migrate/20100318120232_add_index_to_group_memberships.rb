class AddIndexToGroupMemberships < ActiveRecord::Migration
  def self.up
    add_index :group_memberships, :user_id
    add_index :group_memberships, :group_id
  end

  def self.down
    remove_index :group_memberships, :user_id
    remove_index :group_memberships, :group_id
  end
end

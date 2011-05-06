class RemoveInvitedFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :invited
  end

  def self.down
    add_column :users, :invited, :boolean
  end
end

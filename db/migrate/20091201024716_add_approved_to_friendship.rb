class AddApprovedToFriendship < ActiveRecord::Migration
  def self.up
    add_column :friendships, :approved, :boolean, :default => false
  end

  def self.down
    remove_column :friendships, :approved
  end
end

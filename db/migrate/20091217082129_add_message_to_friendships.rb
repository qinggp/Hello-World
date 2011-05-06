class AddMessageToFriendships < ActiveRecord::Migration
  def self.up
    add_column :friendships, :message, :text
  end

  def self.down
    remove_column :friendships, :message
  end
end

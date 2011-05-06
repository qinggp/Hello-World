class AddFriendsCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :friends_count, :integer, :default => 0
  end

  def self.down
    remove_column :users, :friends_count
  end
end

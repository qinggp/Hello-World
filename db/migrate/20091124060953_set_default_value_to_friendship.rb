class SetDefaultValueToFriendship < ActiveRecord::Migration
  def self.up
    remove_column :friendships, :relation
    remove_column :friendships, :contact_frequency
    add_column :friendships, :relation, :integer, :default => 5
    add_column :friendships, :contact_frequency, :integer, :default => 5
  end

  def self.down
    remove_column :friendships, :relation
    remove_column :friendships, :contact_frequency
    add_column :friendships, :relation, :integer
    add_column :friendships, :contact_frequency, :integer
  end
end

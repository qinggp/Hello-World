class AddDescriptionRelationAndContactFrequencyToFriendship < ActiveRecord::Migration
  def self.up
    add_column :friendships, :description, :text
    add_column :friendships, :relation, :integer
    add_column :friendships, :contact_frequency, :integer
  end

  def self.down
    remove_column :friendships, :descrtiption
    remove_column :friendships, :relation
    remove_column :friendships, :contact_frequency
  end
end

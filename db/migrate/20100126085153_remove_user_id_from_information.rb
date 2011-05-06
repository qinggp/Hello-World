class RemoveUserIdFromInformation < ActiveRecord::Migration
  def self.up
    remove_column :information, :user_id
  end

  def self.down
    add_column :information, :user_id, :integer
  end
end

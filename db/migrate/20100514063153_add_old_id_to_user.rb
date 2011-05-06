class AddOldIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :old_id, :integer, :unique => true
    add_index :users, :old_id, :unique => true
  end

  def self.down
    remove_index :users, :old_id
    remove_column :users, :old_id
  end
end

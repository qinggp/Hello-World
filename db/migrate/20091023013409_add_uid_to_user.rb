class AddUidToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :uid, :string, :limit => 100
    add_index :users, :uid, :unique => true
  end

  def self.down
    remove_index :users, :column => :uid
    remove_column :users, :uid
  end
end

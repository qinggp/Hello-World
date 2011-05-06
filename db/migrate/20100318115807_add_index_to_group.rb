class AddIndexToGroup < ActiveRecord::Migration
  def self.up
    add_index :groups, :user_id
  end

  def self.down
    remove_index :groups, :user_id
  end
end

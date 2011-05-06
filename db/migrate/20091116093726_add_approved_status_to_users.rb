class AddApprovedStatusToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :approved_status, :integer, :default => 1
  end

  def self.down
    remove_column :uesrs, :approved_status
  end
end

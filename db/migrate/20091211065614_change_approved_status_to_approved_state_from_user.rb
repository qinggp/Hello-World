class ChangeApprovedStatusToApprovedStateFromUser < ActiveRecord::Migration
  def self.up
    remove_column :users, :approved_status
    add_column :users, :approval_state, :string
  end

  def self.down
    remove_column :users, :approval_state
    add_column :users, :approved_status, :integer
  end
end

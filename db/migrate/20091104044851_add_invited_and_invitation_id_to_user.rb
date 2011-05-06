class AddInvitedAndInvitationIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :invited, :boolean, :default => true
    add_column :users, :invitation_id, :integer
  end

  def self.down
    remove_column :users, :invited
    remove_column :users, :invitation_id
  end
end

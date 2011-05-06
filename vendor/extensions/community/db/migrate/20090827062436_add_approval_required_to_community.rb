class AddApprovalRequiredToCommunity < ActiveRecord::Migration
  def self.up
    add_column :communities, :approval_required, :boolean
  end

  def self.down
    remove_column :communities, :approval_required
  end
end

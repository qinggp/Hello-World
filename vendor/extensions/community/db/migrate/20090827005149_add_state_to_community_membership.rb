class AddStateToCommunityMembership < ActiveRecord::Migration
  def self.up
    add_column :community_memberships, :state, :string
  end

  def self.down
    remove_column :community_memberships, :state
  end
end

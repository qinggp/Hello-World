class AddTypeToCommunityLinkage < ActiveRecord::Migration
  def self.up
    add_column :community_linkages, :type, :string
  end

  def self.down
    remove_column :community_linkages, :type
  end
end

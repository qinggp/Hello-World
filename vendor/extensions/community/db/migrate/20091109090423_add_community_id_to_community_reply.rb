class AddCommunityIdToCommunityReply < ActiveRecord::Migration
  def self.up
    add_column :community_replies, :community_id, :integer
  end

  def self.down
    remove_column :community_replies, :community_id
  end
end

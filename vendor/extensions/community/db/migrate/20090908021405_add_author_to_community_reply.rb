class AddAuthorToCommunityReply < ActiveRecord::Migration
  def self.up
    add_column :community_replies, :user_id, :integer
  end

  def self.down
    remove_column :community_replies, :user_id
  end
end

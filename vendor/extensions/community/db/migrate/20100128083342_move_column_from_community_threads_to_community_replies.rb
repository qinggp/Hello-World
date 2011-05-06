class MoveColumnFromCommunityThreadsToCommunityReplies < ActiveRecord::Migration
  def self.up
    remove_column :community_threads, :deleted
    add_column :community_replies, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :community_replies, :deleted
    add_column :community_threads, :deleted, :boolean
  end
end

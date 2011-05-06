class AddColumnJudgeIdToPendingCommunityUser < ActiveRecord::Migration
  def self.up
    add_column :pending_community_users, :judge_id, :integer
  end

  def self.down
    remove_column :pending_community_users, :judge_id
  end
end

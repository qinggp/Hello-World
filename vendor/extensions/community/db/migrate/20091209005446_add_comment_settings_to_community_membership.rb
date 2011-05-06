class AddCommentSettingsToCommunityMembership < ActiveRecord::Migration
  def self.up
    add_column :community_memberships, :new_comment_displayed, :boolean, :default => true
    add_column :community_memberships, :comment_notice_acceptable, :boolean, :default => false
  end

  def self.down
    remove_column :community_memberships, :comment_notice_acceptable
    remove_column :community_memberships, :new_comment_displayed
  end
end

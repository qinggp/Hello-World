class AddCommentNoticeAcceptablForMobileToCommunityMembership < ActiveRecord::Migration
  def self.up
    add_column :community_memberships, :comment_notice_acceptable_for_mobile, :boolean, :default => false 
  end

  def self.down
    remove_column :community_memberships, :comment_notice_acceptable_for_mobile
  end
end

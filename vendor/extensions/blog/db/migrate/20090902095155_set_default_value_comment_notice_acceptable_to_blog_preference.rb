class SetDefaultValueCommentNoticeAcceptableToBlogPreference < ActiveRecord::Migration
  def self.up
    change_column :blog_preferences, :comment_notice_acceptable, :boolean, :default => false
  end

  def self.down
    change_column :blog_preferences, :comment_notice_acceptable, :boolean
  end
end

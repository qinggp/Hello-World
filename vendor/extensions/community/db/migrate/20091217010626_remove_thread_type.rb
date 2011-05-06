class RemoveThreadType < ActiveRecord::Migration
  def self.up
    remove_column :community_replies, :thread_type
    remove_column :community_thread_attachments, :thread_type
  end

  def self.down
    add_column :community_replies, :thread_type, :string
    add_column :community_thread_attachments, :thread_type, :string
  end
end

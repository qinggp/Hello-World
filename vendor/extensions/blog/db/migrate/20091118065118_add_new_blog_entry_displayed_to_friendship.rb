class AddNewBlogEntryDisplayedToFriendship < ActiveRecord::Migration
  def self.up
    add_column :friendships, :new_blog_entry_displayed, :boolean, :default => true
  end

  def self.down
    remove_column :friendships, :new_blog_entry_displayed
  end
end

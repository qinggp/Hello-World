class AddBlogCommentsCountToBlogEntry < ActiveRecord::Migration
  def self.up
    add_column :blog_entries, :blog_comments_count, :integer, :default => 0
  end

  def self.down
    remove_column :blog_entries, :blog_comments_count
  end
end

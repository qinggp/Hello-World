class AddBlogCategoryIdToBlogEntries < ActiveRecord::Migration
  def self.up
    add_column :blog_entries, :blog_category_id, :integer
  end

  def self.down
    remove_column :blog_entries, :blog_category_id
  end
end

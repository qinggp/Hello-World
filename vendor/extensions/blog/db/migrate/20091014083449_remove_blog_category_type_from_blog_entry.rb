class RemoveBlogCategoryTypeFromBlogEntry < ActiveRecord::Migration
  def self.up
    remove_column :blog_entries, :blog_category_type
  end

  def self.down
    add_column :blog_entries, :blog_category_type, :string
  end
end

class AddBlogCategoryTypeToBlogEntry < ActiveRecord::Migration
  def self.up
    add_column :blog_entries, :blog_category_type, :string
  end

  def self.down
    remove_column :blog_entries, :blog_category_type
  end
end

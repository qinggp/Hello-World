class RemoveDefaultSharedFromBlogCategory < ActiveRecord::Migration
  def self.up
    remove_column :blog_categories, :default
    remove_column :blog_categories, :shared
  end

  def self.down
    add_column :blog_categories, :shared, :boolean
    add_column :blog_categories, :default, :boolean
  end
end

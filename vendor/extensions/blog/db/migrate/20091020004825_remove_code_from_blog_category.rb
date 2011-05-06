class RemoveCodeFromBlogCategory < ActiveRecord::Migration
  def self.up
    remove_column :blog_categories, :code
  end

  def self.down
    add_column :blog_categories, :code, :string
  end
end

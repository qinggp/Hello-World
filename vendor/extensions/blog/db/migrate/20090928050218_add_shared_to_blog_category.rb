class AddSharedToBlogCategory < ActiveRecord::Migration
  def self.up
    add_column :blog_categories, :shared, :boolean, :default => true
  end

  def self.down
    remove_column :blog_categories, :shared
  end
end

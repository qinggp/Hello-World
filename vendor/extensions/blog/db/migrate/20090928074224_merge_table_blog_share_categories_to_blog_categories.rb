class MergeTableBlogShareCategoriesToBlogCategories < ActiveRecord::Migration
  def self.up
    drop_table :blog_share_categories
    add_column :blog_categories, :shared, :boolean, :default => false
    add_column :blog_categories, :code, :string
    add_index :blog_categories, :code, :unique => true
  end

  def self.down
    create_table :blog_share_categories do |t|
      t.string :code, :unique => true
      t.string :name

      t.timestamps
    end
    add_index :blog_share_categories, :code, :unique => true

    remove_column :blog_categories, :shared
    remove_column :blog_categories, :code
  end
end

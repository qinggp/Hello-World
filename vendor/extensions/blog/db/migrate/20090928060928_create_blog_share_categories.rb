class CreateBlogShareCategories < ActiveRecord::Migration
  def self.up
    create_table :blog_share_categories do |t|
      t.string :code, :unique => true
      t.string :name

      t.timestamps
    end
    add_index :blog_share_categories, :code, :unique => true
  end

  def self.down
    drop_table :blog_share_categories
  end
end

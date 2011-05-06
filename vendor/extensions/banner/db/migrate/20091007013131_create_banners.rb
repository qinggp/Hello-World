class CreateBanners < ActiveRecord::Migration
  def self.up
    create_table :banners do |t|

      t.string :image
      t.string :link_url
      t.text :comment
      t.datetime :expire_date
      t.integer :click_count, :default => 0
      
      t.timestamps
    end
    add_index :banners, :expire_date
    add_index :banners, :click_count
    add_index :banners, :created_at
  end

  def self.down
    remove_index :banners, :expire_date
    remove_index :banners, :click_count
    remove_index :banners, :created_at
    
    drop_table :banners
  end
  
end

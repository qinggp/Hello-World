class CreateCommunityMapCategories < ActiveRecord::Migration
  def self.up
    create_table :community_map_categories do |t|
      t.string :name
      t.integer :user_id
      t.integer :community_id
      t.timestamps
    end
  end

  def self.down
    drop_table :community_map_categories
  end
end

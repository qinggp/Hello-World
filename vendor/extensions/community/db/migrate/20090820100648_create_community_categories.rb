class CreateCommunityCategories < ActiveRecord::Migration
  def self.up
    create_table :community_categories do |t|
      t.string :name
      t.integer :parent_id
      t.timestamps
    end
  end

  def self.down
    drop_table :community_categories
  end
end

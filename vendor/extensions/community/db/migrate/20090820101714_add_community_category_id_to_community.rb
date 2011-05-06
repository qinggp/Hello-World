class AddCommunityCategoryIdToCommunity < ActiveRecord::Migration
  def self.up
    add_column :communities, :community_category_id, :integer
  end

  def self.down
    remove_column :communities, :community_category_id
  end
end

class AddCounterCacheColumnToCommunities < ActiveRecord::Migration
  def self.up
    add_column :communities, :topics_count, :integer, :null => false, :default => 0
    add_column :communities, :events_count, :integer, :null => false, :default => 0
    add_column :communities, :markers_count, :integer, :null => false, :default => 0
    add_column :communities, :members_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :communities, :topics_count
    remove_column :communities, :events_count
    remove_column :communities, :markers_count
    remove_column :communities, :members_count
  end
end

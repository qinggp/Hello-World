class ChangeColumnTypeString < ActiveRecord::Migration
  def self.up
    change_column :communities, :name, :text

    change_column :community_threads, :title, :text

    change_column :community_map_categories, :name, :text

    change_column :community_groups, :name, :text
  end

  def self.down
    change_column :communities, :name, :string

    change_column :community_threads, :title, :string

    change_column :community_map_categories, :name, :string

    change_column :community_groups, :name, :string
  end
end

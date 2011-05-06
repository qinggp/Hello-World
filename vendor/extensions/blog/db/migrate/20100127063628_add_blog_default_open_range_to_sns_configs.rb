class AddBlogDefaultOpenRangeToSnsConfigs < ActiveRecord::Migration
  def self.up
    add_column :sns_configs, :blog_default_open_range, :integer
  end

  def self.down
    remove_column :sns_configs, :blog_default_open_range
  end
end

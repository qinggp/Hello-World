class RemoveBlogDefaultOpenRangeAndRankingDisplayFlgFromSnsConfigs < ActiveRecord::Migration
  def self.up
    remove_column :sns_configs, :blog_default_open_range
    remove_column :sns_configs, :ranking_display_flg
  end

  def self.down
    add_column :sns_configs, :ranking_display_flg, :boolean
    add_column :sns_configs, :blog_default_open_range, :integer
  end
end

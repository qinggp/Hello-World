class AddRankingDisplayFlgFromSnsConfigs < ActiveRecord::Migration
  def self.up
    add_column :sns_configs, :ranking_display_flg, :boolean, :default => true
  end

  def self.down
    remove_column :sns_configs, :ranking_display_flg
  end
end

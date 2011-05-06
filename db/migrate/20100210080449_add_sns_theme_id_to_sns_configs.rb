class AddSnsThemeIdToSnsConfigs < ActiveRecord::Migration
  def self.up
    add_column :sns_configs, :sns_theme_id, :integer
  end

  def self.down
    remove_column :sns_configs, :sns_theme_id
  end
end

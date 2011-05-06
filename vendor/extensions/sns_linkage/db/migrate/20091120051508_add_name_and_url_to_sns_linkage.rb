class AddNameAndUrlToSnsLinkage < ActiveRecord::Migration
  def self.up
    add_column :sns_linkages, :name, :text
    add_column :sns_linkages, :url, :text
  end

  def self.down
    remove_column :sns_linkages, :url
    remove_column :sns_linkages, :name
  end
end

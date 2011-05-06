class AddSnsLinkKeyToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :sns_link_key, :string
  end

  def self.down
    remove_column :users, :sns_link_key
  end
end

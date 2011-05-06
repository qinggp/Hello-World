class AddOfficialToCommunity < ActiveRecord::Migration
  def self.up
    add_column :communities, :official, :boolean
  end

  def self.down
    remove_column :communities, :official
  end
end

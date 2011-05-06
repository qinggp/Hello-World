class SetDefaultValueOfficialOfCommunities < ActiveRecord::Migration
  def self.up
    remove_column :communities, :official
    add_column :communities, :official, :integer, :default => 1
  end

  def self.down
    remove_column :communities, :official
    add_column :communities, :official, :integer
  end
end

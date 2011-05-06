class ChangeOfficialFromCommunity < ActiveRecord::Migration
  def self.up
    remove_column :communities, :official
    add_column :communities, :official, :integer
  end

  def self.down
    remove_column :communities, :official
    add_column :communities, :official, :boolean
  end
end

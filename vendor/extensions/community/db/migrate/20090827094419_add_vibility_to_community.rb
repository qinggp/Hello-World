class AddVibilityToCommunity < ActiveRecord::Migration
  def self.up
    add_column :communities, :visibility, :integer
  end

  def self.down
    remove_column :communities, :visibility
  end
end

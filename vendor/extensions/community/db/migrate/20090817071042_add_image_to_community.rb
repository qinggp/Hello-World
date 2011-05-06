class AddImageToCommunity < ActiveRecord::Migration
  def self.up
    add_column :communities, :image, :string
  end

  def self.down
    remove_column :communities, :image
  end
end

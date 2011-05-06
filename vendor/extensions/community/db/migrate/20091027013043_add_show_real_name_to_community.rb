class AddShowRealNameToCommunity < ActiveRecord::Migration
  def self.up
    add_column :communities, :show_real_name, :boolean

  end

  def self.down
    remove_column :communities, :show_real_name
  end
end

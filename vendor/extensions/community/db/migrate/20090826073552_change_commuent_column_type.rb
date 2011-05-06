class ChangeCommuentColumnType < ActiveRecord::Migration
  def self.up
    change_column :communities, :comment, :text
  end

  def self.down
    change_column :communities, :comment, :string
  end
end

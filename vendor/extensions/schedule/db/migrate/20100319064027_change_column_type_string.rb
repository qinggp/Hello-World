class ChangeColumnTypeString < ActiveRecord::Migration
  def self.up
    change_column :schedules, :title, :text
  end

  def self.down
    change_column :schedules, :title, :string
  end
end

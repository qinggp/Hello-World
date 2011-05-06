class AddAccessCountToBlogEntry < ActiveRecord::Migration
  def self.up
    add_column :blog_entries, :access_count, :integer, :default => 0
  end

  def self.down
    remove_column :blog_entries, :access_count
  end
end

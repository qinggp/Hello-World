class AddOldIdToBlogEntry < ActiveRecord::Migration
  def self.up
    add_column :blog_entries, :old_id, :integer, :unique => true
    add_index :blog_entries, :old_id, :unique => true
  end

  def self.down
    remove_index :blog_entries, :old_id
    remove_column :blog_entries, :old_id
  end
end

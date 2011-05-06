class AddBodyFormatToBlogEntry < ActiveRecord::Migration
  def self.up
    add_column :blog_entries, :body_format, :string
  end

  def self.down
    remove_column :blog_entries, :body_format
  end
end

class AddLongitudeAndLatitudeAndZoomToBlogEntry < ActiveRecord::Migration
  def self.up
    add_column :blog_entries, :longitude, :decimal, :scale => 6, :precision => 9
    add_column :blog_entries, :latitude, :decimal, :scale => 6, :precision => 9
    add_column :blog_entries, :zoom, :integer
  end

  def self.down
    remove_column :blog_entries, :zoom
    remove_column :blog_entries, :latitude
    remove_column :blog_entries, :longitude
  end
end

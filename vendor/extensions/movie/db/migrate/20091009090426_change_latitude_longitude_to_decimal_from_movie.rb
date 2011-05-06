class ChangeLatitudeLongitudeToDecimalFromMovie < ActiveRecord::Migration
  def self.up
    remove_column :movies, :latitude
    add_column :movies, :latitude, :decimal, :scale => 6, :precision => 9
    remove_column :movies, :longitude
    add_column :movies, :longitude, :decimal, :scale => 6, :precision => 9
  end

  def self.down
    remove_column :movies, :latitude
    add_column :movies, :latitude, :string
    remove_column :movies, :longitude
    add_column :movies, :longitude, :string
  end
end

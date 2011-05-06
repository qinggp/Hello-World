class AddIndexToTracks < ActiveRecord::Migration
  def self.up
    add_index :tracks, :user_id
    add_index :tracks, :visitor_id
    add_index :tracks, :page_type
  end

  def self.down
    remove_index :tracks, :user_id
    remove_index :tracks, :visitor_id
    remove_index :tracks, :page_type
  end
end

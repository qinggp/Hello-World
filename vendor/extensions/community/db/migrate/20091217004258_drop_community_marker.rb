class DropCommunityMarker < ActiveRecord::Migration
  def self.up
    drop_table :community_markers
  end

  def self.down
    create_table :community_markers do |t|
      t.string :title
      t.text :content
      t.decimal :latitude, :scale => 6, :precision => 9
      t.decimal :longitude, :scale => 6, :precision => 9
      t.integer :zoom
      t.boolean :deleted
      t.integer :user_id
      t.integer :community_id
      t.boolean  :public
      t.integer :community_map_category_id

      t.timesstamps
    end
  end
end

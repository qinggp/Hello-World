class DropCommunityEvent < ActiveRecord::Migration
  def self.up
    drop_table :community_events
  end

  def self.down
    create_table :community_events do |t|
      t.string :title
      t.text :content
      t.date :event_date
      t.string :event_date_note
      t.string :place
      t.decimal :latitude, :scale => 6, :precision => 9
      t.decimal :longitude, :scale => 6, :precision => 9
      t.integer :zoom
      t.boolean :deleted
      t.integer :user_id
      t.integer :community_id
      t.boolean  :public

      t.timestamps
    end
  end
end

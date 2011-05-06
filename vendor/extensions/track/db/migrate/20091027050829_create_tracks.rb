class CreateTracks < ActiveRecord::Migration
  def self.up
    create_table :tracks do |t|
      t.integer :user_id
      t.integer :visitor_id
      t.integer :page_type

      t.timestamps
    end
  end

  def self.down
    drop_table :tracks
  end
end
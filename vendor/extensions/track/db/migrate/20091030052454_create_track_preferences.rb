class CreateTrackPreferences < ActiveRecord::Migration
  def self.up
    create_table :track_preferences do |t|
      t.integer :preference_id
      t.integer :notification_track_count

      t.timestamps
    end
  end

  def self.down
    drop_table :track_preferences
  end
end

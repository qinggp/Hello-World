class CreateSchedulePreferences < ActiveRecord::Migration
  def self.up
    create_table :schedule_preferences do |t|
      t.integer :preference_id
      t.integer :visibility

      t.timestamps
    end
  end

  def self.down
    drop_table :schedule_preferences
  end
end

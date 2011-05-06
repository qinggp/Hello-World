class CreateMoviePreferences < ActiveRecord::Migration
  def self.up
    create_table :movie_preferences do |t|
      t.integer :preference_id
      t.integer :default_visibility

      t.timestamps
    end
  end

  def self.down
    drop_table :movie_preferences
  end
end

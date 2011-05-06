class AddSkypeIdAndYahooIdToPreference < ActiveRecord::Migration
  def self.up
    add_column :preferences, :skype_id, :string
    add_column :preferences, :skype_id_visibility, :integer
    add_column :preferences, :skype_mode, :integer
    add_column :preferences, :yahoo_id, :string
    add_column :preferences, :yahoo_id_visibility, :integer
  end

  def self.down
    remove_column :preferences, :yahoo_id_visibility
    remove_column :preferences, :yahoo_id
    remove_column :preferences, :skype_mode
    remove_column :preferences, :skype_id_visibility
    remove_column :preferences, :skype_id
  end
end

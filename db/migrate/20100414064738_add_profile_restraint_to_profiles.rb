class AddProfileRestraintToProfiles < ActiveRecord::Migration
  def self.up
    add_column :preferences, :profile_restraint_type, :boolean, :default => true
  end

  def self.down
    remove_column :preferences, :profile_restraint_type
  end
end

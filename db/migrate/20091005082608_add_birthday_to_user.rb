class AddBirthdayToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :birthday, :date
    add_column :users, :birthday_visibility, :integer
  end

  def self.down
    remove_column :users, :birthday
    remove_column :users, :birthday_visibility
  end
end


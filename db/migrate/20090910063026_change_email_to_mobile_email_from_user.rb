class ChangeEmailToMobileEmailFromUser < ActiveRecord::Migration
  def self.up
    rename_column :users, :email, :mobile_email
    change_column :users, :login, :string, :limit => 100
  end

  def self.down
    rename_column :users, :mobile_email, :email
    change_column :users, :login, :string, :limit => 40
  end
end

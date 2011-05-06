class RenameUidToMobileIdentFromUsers < ActiveRecord::Migration
  def self.up
    rename_column :users, :uid, :mobile_ident
  end

  def self.down
    rename_column :users, :mobile_ident, :uid
  end
end

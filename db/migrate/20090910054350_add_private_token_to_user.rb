class AddPrivateTokenToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :private_token, :string, :limit => 10
  end

  def self.down
    remove_column :users, :private_token
  end
end

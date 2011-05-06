class RemoveColumnHobbyIdInUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :hobby_id
  end

  def self.down
    add_column :users, :hobby_id, :integer
  end
end

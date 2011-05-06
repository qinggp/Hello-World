class CreatePendingCommunityUsers < ActiveRecord::Migration
  def self.up
    create_table :pending_community_users do |t|
      t.integer :user_id
      t.integer :community_id
      t.text :apply_message
      t.text :reject_message
      t.string :state

      t.timestamps
    end
  end

  def self.down
    drop_table :pending_community_users
  end
end

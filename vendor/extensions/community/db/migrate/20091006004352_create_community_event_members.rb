class CreateCommunityEventMembers < ActiveRecord::Migration
  def self.up
    create_table :community_event_members do |t|
      t.integer :user_id
      t.integer :community_event_id

      t.timestamps
    end
  end

  def self.down
    drop_table :community_event_members
  end
end

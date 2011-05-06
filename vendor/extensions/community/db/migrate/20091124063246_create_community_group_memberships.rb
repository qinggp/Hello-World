class CreateCommunityGroupMemberships < ActiveRecord::Migration
  def self.up
    create_table :community_group_memberships do |t|
      t.integer :community_id
      t.integer :community_group_id

      t.timestamps
    end
  end

  def self.down
    drop_table :community_group_memberships
  end
end

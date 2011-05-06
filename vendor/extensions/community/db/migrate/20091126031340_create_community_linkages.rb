class CreateCommunityLinkages < ActiveRecord::Migration
  def self.up
    create_table :community_linkages do |t|
      t.integer :community_id
      t.integer :user_id
      t.integer :link_id
      t.string :rss_url
      t.string :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :community_linkages
  end
end

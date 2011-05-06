class DropCommunityTopic < ActiveRecord::Migration
  def self.up
    drop_table :community_topics
  end

  def self.down
    create_table :community_topics do |t|
      t.string :title
      t.text :content
      t.deleted :boolean
      t.user_id :integer
      t.community_id :integer
      
      t.timestamps
    end
  end
end

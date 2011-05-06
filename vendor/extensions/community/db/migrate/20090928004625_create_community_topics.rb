class CreateCommunityTopics < ActiveRecord::Migration
  def self.up
    create_table :community_topics do |t|
      t.string :title
      t.text :content
      t.boolean :deleted
      t.integer :user_id
      t.integer :community_id
      t.timestamps
    end
  end

  def self.down
    drop_table :community_topics
  end
end

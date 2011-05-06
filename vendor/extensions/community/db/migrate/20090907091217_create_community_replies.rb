class CreateCommunityReplies < ActiveRecord::Migration
  def self.up
    create_table :community_replies do |t|
      t.integer :thread_id
      t.string :thread_type

      t.integer :parent_id

      t.string :title
      t.text :content
      t.timestamps
    end
  end

  def self.down
    drop_table :community_replies
  end
end

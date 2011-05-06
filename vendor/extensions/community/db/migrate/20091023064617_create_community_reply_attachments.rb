class CreateCommunityReplyAttachments < ActiveRecord::Migration
  def self.up
    create_table :community_reply_attachments do |t|
      t.string :image
      t.integer :position
      t.integer :community_reply_id

      t.timestamps
    end
  end

  def self.down
    drop_table :community_reply_attachments
  end
end

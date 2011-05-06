class CreateCommunityThreadAttachments < ActiveRecord::Migration
  def self.up
    create_table :community_thread_attachments do |t|
      t.string :image
      t.integer :position
      t.integer :thread_id
      t.string :thread_type

      t.timestamps
    end
  end

  def self.down
    drop_table :community_thread_attachments
  end
end

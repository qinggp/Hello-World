class CreateMessageAttachmentAssociations < ActiveRecord::Migration
  def self.up
    create_table :message_attachment_associations do |t|
      t.integer :message_id
      t.integer :message_attachment_id

      t.timestamps
    end
  end

  def self.down
    drop_table :message_attachment_associations
  end
end

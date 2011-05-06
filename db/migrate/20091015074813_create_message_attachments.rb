class CreateMessageAttachments < ActiveRecord::Migration
  def self.up
    create_table :message_attachments do |t|
      t.string :image
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :message_attachments
  end
end

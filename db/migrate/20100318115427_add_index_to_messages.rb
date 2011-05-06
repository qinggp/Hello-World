class AddIndexToMessages < ActiveRecord::Migration
  def self.up
    add_index :messages, :sender_id
    add_index :messages, :receiver_id
    add_index :messages, :unread
    add_index :messages, :deleted_by_sender
    add_index :messages, :deleted_by_receiver

    add_index :message_attachment_associations, :message_id
    add_index :message_attachment_associations, :message_attachment_id
  end

  def self.down
    remove_index :messages, :sender_id
    remove_index :messages, :receiver_id
    remove_index :messages, :unread
    remove_index :messages, :deleted_by_sender
    remove_index :messages, :deleted_by_receiver

    remove_index :message_attachment_associations, :message_id
    remove_index :message_attachment_associations, :message_attachment_id
  end
end

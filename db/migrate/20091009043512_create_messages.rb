class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.integer :sender_id
      t.integer :receiver_id
      t.string :subject
      t.text :body
      t.boolean :unread
      t.boolean :deleted_by_sender
      t.boolean :deleted_by_receiver
      t.boolean :replied

      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end

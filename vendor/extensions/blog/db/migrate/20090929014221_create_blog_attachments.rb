class CreateBlogAttachments < ActiveRecord::Migration
  def self.up
    create_table :blog_attachments do |t|
      t.string :image
      t.integer :blog_entry_id
      t.integer :position

      t.timestamps
    end
    add_index :blog_attachments, [:blog_entry_id, :position], :unique => true
  end

  def self.down
    drop_table :blog_attachments
  end
end

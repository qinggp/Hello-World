class CreateInformation < ActiveRecord::Migration
  def self.up
    create_table :information do |t|
      t.integer :user_id
      t.text :title
      t.text :content
      t.datetime :expire_date
      t.integer :display_type
      t.integer :display_link
      t.integer :public_range
      t.datetime :created_at
      t.datetime :updated_at

      t.timestamps

    end
    add_index :information, :user_id
    add_index :information, :created_at
    add_index :information, :expire_date
    add_index :information, :display_type
    add_index :information, :public_range
  end

  def self.down
    remove_index :information, :user_id
    remove_index :information, :created_at
    remove_index :information, :expire_date
    remove_index :information, :display_type
    remove_index :information, :public_range

    drop_table :information
  end
end

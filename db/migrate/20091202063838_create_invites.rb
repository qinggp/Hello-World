class CreateInvites < ActiveRecord::Migration
  def self.up
    create_table :invites do |t|
      t.string :email
      t.integer :user_id
      t.text :body
      t.integer :relation
      t.integer :contact_frequency
      t.string :state
      t.string :private_token

      t.timestamps
    end
    add_index :invites, [:email, :user_id], :unique =>true
    add_index :invites, :private_token, :unique =>true
  end

  def self.down
    drop_table :invites
  end
end

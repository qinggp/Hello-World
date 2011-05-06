class CreateHobbies < ActiveRecord::Migration
  def self.up
    create_table :hobbies do |t|
      t.string :name
      t.integer :position
    end
    add_index :hobbies, :position, :unique => true
  end

  def self.down
    drop_table :hobbies
  end
end

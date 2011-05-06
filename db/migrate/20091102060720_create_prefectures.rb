class CreatePrefectures < ActiveRecord::Migration
  def self.up
    create_table :prefectures do |t|
      t.string :name
      t.integer :position
    end
    add_index :prefectures, :position, :unique => true
  end

  def self.down
    drop_table :prefectures
  end
end

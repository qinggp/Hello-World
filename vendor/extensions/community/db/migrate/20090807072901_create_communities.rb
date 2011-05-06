class CreateCommunities < ActiveRecord::Migration
  def self.up
    create_table :communities do |t|
      t.string :name
      t.string :comment
      t.decimal :latitude, :scale => 6, :precision => 9
      t.decimal :longitude, :scale => 6, :precision => 9
      t.integer :zoom
      t.timestamps
    end
  end

  def self.down
    drop_table :communities
  end
end

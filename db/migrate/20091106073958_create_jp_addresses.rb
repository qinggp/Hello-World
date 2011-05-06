class CreateJpAddresses < ActiveRecord::Migration
  def self.up
    create_table :jp_addresses do |t|
      t.integer :prefecture_id
      t.string :zipcode
      t.string :city
      t.string :town
    end
  end

  def self.down
    drop_table :jp_addresses
  end
end

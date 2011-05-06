class CreateSpamIpAddresses < ActiveRecord::Migration
  def self.up
    create_table :spam_ip_addresses do |t|
      t.string :ip_address, :unique => true
      t.add_index :ip_address, :unique => true
    end
  end

  def self.down
    drop_table :spam_ip_addresses
  end
end

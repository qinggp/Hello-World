class AddLaspostedAt < ActiveRecord::Migration
  def self.up
    add_column :communities, :lastposted_at, :datetime
    add_column :community_threads, :lastposted_at, :datetime
  end

  def self.down
    remove_column :communities, :lastposted_at
    remove_column :community_threads, :lastposted_at
  end
end

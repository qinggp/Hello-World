class AddParticipationNoticeToCommunity < ActiveRecord::Migration
  def self.up
    add_column :communities, :participation_notice, :boolean
  end

  def self.down
    remove_column :communities, :participation_notice
  end
end

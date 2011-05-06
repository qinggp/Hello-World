class AddCreatableTopicAndMarkerToCommunity < ActiveRecord::Migration
  def self.up
    add_column :communities, :topic_createable_admin_only, :boolean
    add_column :communities, :event_createable_admin_only, :boolean
  end

  def self.down
    remove_column :communities, :topic_createable_admin_only
    remove_column :communities, :event_createable_admin_only
  end
end

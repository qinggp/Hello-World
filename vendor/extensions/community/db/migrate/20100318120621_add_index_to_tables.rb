class AddIndexToTables < ActiveRecord::Migration
  def self.up
    add_index :communities, :community_category_id
    add_index :communities, :visibility
    add_index :communities, :official
    add_index :communities, :lastposted_at

    add_index :community_memberships, :user_id
    add_index :community_memberships, :community_id
    add_index :community_memberships, :state

    add_index :community_linkages, :community_id
    add_index :community_linkages, :user_id
    add_index :community_linkages, :link_id

    add_index :pending_community_users, :user_id
    add_index :pending_community_users, :community_id
    add_index :pending_community_users, :state

    add_index :community_groups, :user_id

    add_index :community_group_memberships, :community_id
    add_index :community_group_memberships, :community_group_id

    add_index :community_map_categories, :community_id

    add_index :community_threads, :event_date
    add_index :community_threads, :user_id
    add_index :community_threads, :community_id
    add_index :community_threads, :public
    add_index :community_threads, :community_map_category_id
    add_index :community_threads, :type
    add_index :community_threads, :lastposted_at

    add_index :community_replies, :thread_id
    add_index :community_replies, :deleted
    add_index :community_replies, :community_id

    add_index :community_thread_attachments, :thread_id

    add_index :community_reply_attachments, :community_reply_id

    add_index :community_categories, :parent_id

    add_index :community_event_members, :user_id
    add_index :community_event_members, :community_event_id
  end

  def self.down
    remove_index :communities, :community_category_id
    remove_index :communities, :visibility
    remove_index :communities, :official
    remove_index :communities, :lastposted_at

    remove_index :community_memberships, :user_id
    remove_index :community_memberships, :community_id
    remove_index :community_memberships, :state

    remove_index :community_linkages, :community_id
    remove_index :community_linkages, :user_id
    remove_index :community_linkages, :link_id

    remove_index :pending_community_users, :user_id
    remove_index :pending_community_users, :community_id
    remove_index :pending_community_users, :state

    remove_index :community_groups, :user_id

    remove_index :community_group_memberships, :community_id
    remove_index :community_group_memberships, :community_group_id

    remove_index :community_map_categories, :community_id

    remove_index :community_threads, :event_date
    remove_index :community_threads, :user_id
    remove_index :community_threads, :community_id
    remove_index :community_threads, :public
    remove_index :community_threads, :community_map_category_id
    remove_index :community_threads, :type
    remove_index :community_threads, :lastposted_at

    remove_index :community_replies, :thread_id
    remove_index :community_replies, :deleted
    remove_index :community_replies, :community_id

    remove_index :community_thread_attachments, :thread_id

    remove_index :community_reply_attachments, :community_reply_id

    remove_index :community_categories, :parent_id

    remove_index :community_event_members, :user_id
    remove_index :community_event_members, :community_event_id
  end
end

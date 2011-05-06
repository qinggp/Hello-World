module Mars::Community::ModelExtension
  module User
    def self.included(base)
      base.class_eval {
        has_many :community_memberships
        has_many :pending_community_users, :dependent => :destroy

        has_many :communities, :through => :community_memberships
        has_many :news_communities, :through => :community_memberships,
                 :source => :community,
                 :conditions => ["community_memberships.new_comment_displayed = ?", true]

        has_many :communities_during_application, :through => :pending_community_users,
                 :source => :community,
                 :conditions => "pending_community_users.state = 'pending'",
                 :order => "communities.id"

        has_many :community_event_members, :dependent => :destroy
        has_many :community_events, :through => :community_event_members
        has_many :community_groups, :dependent => :destroy

        before_destroy { |user| ::Community.post_process_after_user_destroyed(user) }
        after_create { |user| ::Community.add_member_to_official_all_member(user) }
      }
    end
  end
end

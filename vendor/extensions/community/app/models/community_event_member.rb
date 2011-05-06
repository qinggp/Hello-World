# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_event_members
#
#  id                 :integer         not null, primary key
#  user_id            :integer
#  community_event_id :integer
#  created_at         :datetime
#  updated_at         :datetime
#

class CommunityEventMember < ActiveRecord::Base
  belongs_to :user
  belongs_to :community_event, :class_name => "CommunityThread",
             :foreign_key => "community_event_id"
end

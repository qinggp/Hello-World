# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_group_memberships
#
#  id                 :integer         not null, primary key
#  community_id       :integer
#  community_group_id :integer
#  created_at         :datetime
#  updated_at         :datetime
#

class CommunityGroupMembership < ActiveRecord::Base
  belongs_to :community_group
  belongs_to :community
end

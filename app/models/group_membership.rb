# == Schema Information
# Schema version: 20100227074439
#
# Table name: group_memberships
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  group_id   :integer
#  created_at :datetime
#  updated_at :datetime
#

class GroupMembership < ActiveRecord::Base
  belongs_to :group
  belongs_to :user
  attr_protected :user_id, :group_id
end

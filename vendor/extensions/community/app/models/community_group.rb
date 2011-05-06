# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_groups
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class CommunityGroup < ActiveRecord::Base
  has_many :community_group_memberships, :dependent => :destroy
  has_many :communities, :through => :community_group_memberships, :source => "community"

  belongs_to :user

  @@default_index_order = 'community_groups.name'
  cattr_reader :default_index_order

  @@presence_of_columns = [:name]
  cattr_accessor :presence_of_columns
  validates_presence_of @@presence_of_columns

  # グループにコミュニティが属しているかどうかを返す
  def has_community?(community)
    self.communities.map(&:id).include?(community.id)
  end

  # グループにコミュニティを追加する
  # ユーザがコミュニティに参加していないときや、既にグループに含まれているときはfalseを返す
  # また、何らかの理由で追加できなかったときもfalseを返す
  def add_community(community)
    if community.member?(self.user) && !self.has_community?(community)
      self.communities << community
      return true if self.has_community?(community)
    end
    return false
  end

  # グループからコミュニティを削除する
  # ユーザがコミュニティに参加していないときや、グループに含まれていないときはfalseを返す
  # また、何らかの理由で削除できなかったときもfalseを返す
  def remove_community(community)
    if community.member?(self.user) && self.has_community?(community)
      self.communities.delete(community)
      return true unless self.has_community?(community)
    end
    return false
  end
end

# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_linkages
#
#  id           :integer         not null, primary key
#  community_id :integer
#  user_id      :integer
#  link_id      :integer
#  rss_url      :string(255)
#  comment      :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  type         :string(255)
#

class CommunityLinkage < ActiveRecord::Base
  belongs_to :user
  belongs_to :owner, :class_name => "Community", :foreign_key => "community_id"
  belongs_to :inner_link, :class_name => "Community", :foreign_key => "link_id"

  @@default_index_order = 'community_linkages.created_at DESC'
  cattr_accessor :default_index_order

  def self.construct_linkage(attr)
    type = attr.delete(:kind)
    if type == "CommunityInnerLinkage"
      CommunityInnerLinkage.new attr
    elsif type == "CommunityOuterLinkage"
      CommunityOuterLinkage.new attr
    else
      self.new attr
    end
  end

  def kind
    self[:type]
  end

  def kind=(type)
    self[:type] = type
  end

  # 内部リンクかどうかを返す
  def inner_link?
    self.inner_link == nil
  end

  # 外部リンクかどうかを返す
  def outer_link?
    self.inner_link != nil
  end
end

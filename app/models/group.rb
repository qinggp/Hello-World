# == Schema Information
# Schema version: 20100227074439
#
# Table name: groups
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Group < ActiveRecord::Base
  has_many :group_memberships, :dependent => :destroy
  has_many :friends, :through => :group_memberships, :source => "user", :uniq => true

  belongs_to :user

  @@default_index_order = 'groups.name'
  cattr_reader :default_index_order
  attr_protected :user_id

  validates_presence_of :name

  # メンバーをグループに追加する
  # トモダチでないときや既にグループに含まれているときはfalseを返す
  # また、何らかの理由で追加できなかったときも同様にfalseを返す
  def add_friend(friend)
    if self.user.friend_user?(friend) && !self.group_member?(friend)
      self.friends << friend
      return true if group_member?(friend)
    end
    return false
  end

  # メンバーをグループから削除する
  # トモダチでないときや既にグループから除外されているときはfalseを返す
  # また、何らかの理由で削除できなかったときも同様にfalseを返す
  def remove_friend(friend)
    if self.user.friend_user?(friend) && self.group_member?(friend)
      self.friends.delete(friend)
      return true unless group_member?(friend)
    end
    return false
  end

  # トモダチがグループに含まれているか
  def group_member?(friend)
    self.friends.map(&:id).include?(friend.try(:id))

  end
end

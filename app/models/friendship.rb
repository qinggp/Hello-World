# == Schema Information
# Schema version: 20100227074439
#
# Table name: friendships
#
#  id                       :integer         not null, primary key
#  user_id                  :integer
#  friend_id                :integer
#  created_at               :datetime
#  updated_at               :datetime
#  description              :text
#  relation                 :integer         default(5)
#  contact_frequency        :integer         default(5)
#  approved                 :boolean
#  message                  :text
#  new_blog_entry_displayed :boolean         default(TRUE)
#

class Friendship < ActiveRecord::Base
  belongs_to :user
  belongs_to :friend, :foreign_key => :friend_id, :class_name => "User"

  # トモダチ数のカウント設定
  after_save :update_friends_count
  after_destroy :update_friends_count

  # あるユーザのトモダチ申請中一覧取得
  named_scope :by_applied_for_user, lambda{|user|
    cond = ["friendships.user_id = ? AND friendships.approved = ?",
           user.id, false]
    {:conditions => cond}
  }

  # あるユーザへのトモダチ申請中一覧取得
  named_scope :by_applied_to_user, lambda{|user|
    cond = ["friendships.friend_id = ? AND friendships.approved = ?",
           user.id, false]
    {:conditions => cond}
  }

  # 関係の深さ: 肉親・恋人, 親友・恩師, 友人・同僚, 知人, これから
  enum_column :relation, :relative_or_lover, :good_friend_or_teacher, :peer, :acquaintance, :nothing
  # 接触の頻度:頻繁, 月イチ, 年イチ, イマイチ, これから
  enum_column :contact_frequency, :many, :once_a_month, :once_a_year, :few, :nothing

  @@default_index_order = 'friendships.created_at DESC'
  cattr_reader :default_index_order
  attr_protected :friend_id, :user_id, :created_at, :updated_at

  validates_presence_of :user_id, :friend_id
  validates_inclusion_of :relation, :in => RELATIONS.values
  validates_inclusion_of :contact_frequency, :in => CONTACT_FREQUENCIES.values
  validates_uniqueness_of :user_id, :scope => [:friend_id]
  validates_uniqueness_of :friend_id, :scope => [:user_id]

  # 紹介文を削除し、関係の深さと接触の頻度をデフォルト値に設定する
  def clear_description!
    self.update_attributes!(:description => nil,
                            :relation => RELATIONS[:nothing],
                            :contact_frequency => CONTACT_FREQUENCIES[:nothing])
  end

  # 紹介文作成用のvalid?メソッド
  def valid_for_edit_description?
    valid?
    self.errors.add_on_blank :description
    return errors.empty?
  end

  private

  # userのトモダチ数を設定
  def update_friends_count
    user.update_attribute(:friends_count, user.friends.count)
  end
end

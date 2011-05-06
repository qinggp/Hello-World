# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_memberships
#
#  id                                   :integer         not null, primary key
#  user_id                              :integer
#  community_id                         :integer
#  created_at                           :datetime
#  updated_at                           :datetime
#  state                                :string(255)
#  new_comment_displayed                :boolean         default(TRUE)
#  comment_notice_acceptable            :boolean
#  comment_notice_acceptable_for_mobile :boolean
#

class CommunityMembership < ActiveRecord::Base
  belongs_to :community
  belongs_to :user

  # メンバー数のカウント設定
  after_save :update_members_count
  after_destroy :update_members_count

  # コミュニティで絞り込み
  named_scope :by_community, lambda {|community|
    {:conditions => ["community_memberships.community_id = ?", community.id] }
  }

  # 管理者権限を持つコミュニティを取得するメソッド
  def self.admin_communities(user)
    return Community.find_by_sql([%Q(select communities.* from communities INNER JOIN roles on roles.name = 'community_admin' and roles.authorizable_type = 'Community' and roles.authorizable_id = communities.id INNER JOIN roles_users ON roles_users.role_id = roles.id WHERE roles_users.user_id = ?), user.id])
  end

  # コミュニティをメンバー数でソートする場合にイベント数をカウントするSQLを返す
  # order by句のサブクエリとして使用する
  def self.sql_for_sort_by_count
    %Q(SELECT count(*) FROM community_memberships WHERE communities.id = community_memberships.community_id)
  end

  private

  # communityのメンバー数を設定
  def update_members_count
    community.update_attribute(:members_count, community.members.count)
  end
end

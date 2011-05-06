# == Schema Information
# Schema version: 20100227074439
#
# Table name: communities
#
#  id                          :integer         not null, primary key
#  name                        :string(255)
#  comment                     :text
#  latitude                    :decimal(9, 6)
#  longitude                   :decimal(9, 6)
#  zoom                        :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  image                       :string(255)
#  community_category_id       :integer
#  approval_required           :boolean
#  visibility                  :integer
#  topic_createable_admin_only :boolean
#  event_createable_admin_only :boolean
#  participation_notice        :boolean
#  show_real_name              :boolean
#  official                    :integer         default(1)
#  lastposted_at               :datetime
#

class Community < ActiveRecord::Base
  has_many :community_memberships, :dependent => :destroy
  has_many :pending_community_users, :dependent => :destroy
  has_many :threads, :class_name => "CommunityThread", :order => "created_at desc",
           :dependent => :destroy
  has_many :events, :class_name => "CommunityEvent", :order => "created_at desc"
  has_many :topics, :class_name => "CommunityTopic", :order => "created_at desc"
  has_many :markers, :class_name => "CommunityMarker", :order => "created_at desc",
           :dependent => :destroy
  has_many :map_categories, :class_name => "CommunityMapCategory", :order => "created_at desc",
           :dependent => :destroy
  has_many :replies, :class_name => "CommunityReply", :order => "created_at desc",
           :dependent => :destroy
  has_many :linkages, :order => "created_at desc", :class_name => "CommunityLinkage",
           :foreign_key => "community_id", :dependent => :destroy
  has_many :linkages_from, :class_name => "CommunityLinkage",
           :foreign_key => "link_id", :dependent => :destroy

  # acts_as_authorization_objectを宣言すると、usersという関連が定義されるので、
  # ここではmembersという関連を定義する
  has_many :members, :through => :community_memberships,
           :source => :user, :conditions => "users.approval_state = 'active'"

  has_many :comment_notice_acceptable_members, :through => :community_memberships,
           :source => :user,
           :conditions => ["comment_notice_acceptable = ?", true]

  has_many :comment_notice_acceptable_members_for_mobile, :through => :community_memberships,
           :source => :user,
           :conditions => ["comment_notice_acceptable_for_mobile = ?", true]

  has_many :pending_users, :through => :pending_community_users,
           :source => :user,
           :conditions => "pending_community_users.state = 'pending'"

  has_many :invited_users, :through => :pending_community_users,
           :source => :user,
           :conditions => "pending_community_users.state = 'invited'"

  has_many :rejected_users, :through => :pending_community_users,
           :source => :user,
           :conditions => "pending_community_users.state = 'rejected'"

  belongs_to :community_category
  has_many :community_group_memberships, :dependent => :destroy
  has_many :groups, :through => :community_group_memberships, :source => "community_group"

  before_create :set_lastposted_at

  file_column :image,
              :magick => {
                :versions => {
                  :thumb => "76",
                  :medium => "200"}
  }

  validates_file_format_of :image, :in => ["jpg", "jpeg", "png", "gif"]
  validates_filesize_of :image, :in => 0..300.kilobytes

  @@presence_of_columns = [:name, :comment, :community_category_id, :participation_and_visibility, :topic_createable_admin_only, :event_createable_admin_only, :participation_notice]
  cattr_reader :presence_of_columns

  validates_presence_of [:name, :comment, :community_category_id, :participation_and_visibility]
  validates_inclusion_of :topic_createable_admin_only, :event_createable_admin_only, :participation_notice, :in => [true, false]

  acts_as_authorization_object

  @@default_index_order = 'communities.lastposted_at DESC'
  cattr_accessor :default_index_order

  @@all_roles = %w(community_general, community_sub_admin, community_admin)
  cattr_accessor :all_roles

  named_scope :by_pending_user, lambda{ |user| { :conditions => ["user_id = ? AND state = 'pending'", user.id] }}

  # ないしょのコミュニティ以外を取得
  named_scope :not_secret, lambda {
    {:conditions => ["visibility != ?", VISIBILITIES[:secret]] }
  }

  # 非公開のコミュニティ以外を取得
  named_scope :not_private, lambda {
    {:conditions => ["visibility != ?", VISIBILITIES[:private]] }
  }

  # オフィシャルのコミュニティを取得
  named_scope :official, lambda {
    { :conditions => ["official != ?", OFFICIALS[:none]] }
  }

  # オフィシャル以外のコミュニティを取得
  named_scope :not_official, lambda {
    { :conditions => ["official = ?", OFFICIALS[:none]] }
  }

  # 外部公開しているコミュニティを取得
  named_scope :public,  lambda {
    {:conditions => ["visibility = ?", VISIBILITIES[:public]] }
  }

  # 公開範囲を表す定数定義
  enum_column :visibility, :private, :member, :public, :secret

  # コミュニティ作成・編集時に承認の有無と公開条件とを同時に選択しているために、
  # ここでその値を定数としてを定義する
  enum_column :approvals_and_visibilities,
              :member,                        # 誰でもOK！[ 全体公開 ]
              :approval_required_and_member,  # 承認必要！[ 全体公開 ]
              :approval_required_and_private, # 承認必要！[ 非公開 ]
              :public,                        # 誰でもOK！[ 外部公開 ]
              :approval_required_and_public,  # 承認必要！[ 外部公開 ]
              :secret                         # ないしょ

  # 上記定数から、承認の有無、並びに公開条件へ変換するテーブル
  CONVENTION_TABLE = {
    :public => [false, VISIBILITIES[:public]],
    :approval_required_and_member => [true, VISIBILITIES[:member]],
    :approval_required_and_private => [true, VISIBILITIES[:private]],
    :member => [false, VISIBILITIES[:member]],
    :approval_required_and_public => [true, VISIBILITIES[:public]],
    :secret => [false, VISIBILITIES[:secret]]
  }

  # コミュニティ区分
  enum_column :official,
              :none,        # 通常コミュニティ
              :normal,      # 公認コミュニティ
              :all_member,  # 公認コミュニティ（全員）
              :admin_only   # 公認コミュニティ（管理人）

  def approval_required?
    approval_required
  end

  # approval_requiredとvisibilityの値から、APPROVALS_AND_VISIBILITIESの数値を取り出す
  def participation_and_visibility
    key = CONVENTION_TABLE.invert[[self.approval_required, self.visibility]]
    APPROVALS_AND_VISIBILITIES[key]
  end

  # CONVENTION_TABLEからapproval_requiredとvisibilityの値を取り出し、
  # それぞれのフィールドにセットする
  def participation_and_visibility=(value)
    key = APPROVALS_AND_VISIBILITIES.invert[value.to_i]
    array = CONVENTION_TABLE[key]
    self.approval_required = array[0]
    self.visibility = array[1]
  end

  # 画像の削除
  def delete_image=(value)
    self.image = nil  if value.to_i == 1
  end

  # 公開条件の説明
  def describe_visibility
    I18n.t("community.visibility.#{visibility_name}")
  end

  # 公開条件の注釈
  def describe_note_of_visibility
    I18n.t("community.note_of_visibility.#{visibility_name}")
  end

  # 承認の有無と、公開条件の説明
  def self.describe_participation_and_visibility(approval_required, visibility)
    description = I18n.t("community.approval_required")[approval_required]
    description += "[ " + I18n.t("community.visibility.#{VISIBILITIES.invert[visibility]}") + " ]"
  end

  # 承認の有無と公開条件を表した数値と、その説明を組にした配列を返す
  def self.participation_and_visibility_list
    APPROVALS_AND_VISIBILITIES.reject{ |k, v| k == :secret }.sort_by{ |a| a[1] }.map do |array|
      participation = CONVENTION_TABLE[array[0]].first
      visibility = CONVENTION_TABLE[array[0]].second
      [array[1], describe_participation_and_visibility(participation, visibility)]
    end
  end

  # 上記メソッドの戻り値を、selectで使用しやすいようにした配列を返す
  def self.participation_and_visibility_list_for_select
    self.participation_and_visibility_list.map do |array|
      [array[1], array[0]]
    end
  end

  # 管理者メニューでの承認の有無と公開条件を表した数値と、その説明を組にした配列を返す
  def self.admin_participation_and_visibility_list
    APPROVALS_AND_VISIBILITIES.sort_by{ |a| a[1] }.map do |array|
      participation = CONVENTION_TABLE[array[0]].first
      visibility = CONVENTION_TABLE[array[0]].second
      [array[1], describe_participation_and_visibility(participation, visibility)]
    end
  end

  # コミュニティへの参加や、参加依頼があったときにメール通知を行うか
  def participation_notice?
    self.participation_notice
  end

  # コミュニティに参加しているかどうか
  def member?(user)
    user && self.members.exists?(user.id)
  end

  # コミュニティに参加申請中かどうか
  def pending?(user)
    user && self.pending_users.exists?(user.id)
  end

  # userが招待された状態であるか
  # ただし、コミュニティ自体が承認制で無い場合falseを返す
  def invited?(user)
    user && self.invited_users.exists?(user.id)
  end

  # コミュニティへの参加依頼を受け取ったときの動作
  def receive_application(user, message = nil)
    if self.approval_required? && !self.invited?(user)
      # 承認制で、招待されていないとき
      pcu = PendingCommunityUser.create!(:user_id => user.id,
                                         :community_id => self.id,
                                         :apply_message => message)
      if self.participation_notice?
        # 参加承認依頼メールを送信する
        self.admin_and_sub_admins.each do |admin_member|
          mail = CommunityParticipationNotifier.create_application(pcu, admin_member)
          message = Message.new(Message.default_attributes({:body => NKF::nkf("-w8", mail.body),
                                                             :receiver_id => admin_member.id,
                                                             :subject => "#{user.name}さんがコミュニティに参加希望しています"},
                                                           user))
          message.save!
          CommunityParticipationNotifier.deliver(mail)
        end
      end
    else
      if self.approval_required? && self.invited?(user)
        # 承認制で、招待を受けていた場合、状態を参加状態にする
        PendingCommunityUser.by_invited_user(user).by_community(self).first.activate_from_invited!
      end

      # 後の処理は、承認制で招待を受けていない場合も、承認制で無かった場合も同じ
      self.members << user
      user.has_role!(:community_general, self)
      if self.participation_notice?
        # 参加通知メールの送信、及びメッセージの作成を行う
        self.admin_and_sub_admins.each do |admin_member|
          mail = CommunityParticipationNotifier.create_notification(self, user, admin_member)
          message = Message.new(Message.default_attributes({:body => NKF::nkf("-w8", mail.body),
                                                             :receiver_id => admin_member.id,
                                                             :subject => "#{user.name}さんがコミュニティに参加しました"},
                                                           user))
          message.save!
          CommunityParticipationNotifier.deliver(mail)
        end
      end
    end
  end

  # コミュニティの参加が最も古い
  # 引数:role名
  # 戻り値:user
  def get_oldest_role_user(role)
    unless role.blank?
      sub_admin_member_ships = Array.new
      unless self.community_memberships.blank?
        self.community_memberships.each do |comu_member|
          user = User.find(comu_member.user_id)
          if user.has_role?(role, self) && user.id != self.admin.id
            sub_admin_member_ships << comu_member
          end
        end
      end
      unless sub_admin_member_ships.blank?
        membership = sub_admin_member_ships.sort{ |b,a| a.created_at <=> b.created_at }.last
        return User.find(membership.user_id)
      else
        return nil
      end
    end
  end

  # コミュニティの管理人を取得する
  def admin
    self.members.detect{ |member| member.has_role?("community_admin", self) }
  end

  # コミュニティの副管理人を取得する
  def sub_admins
    self.members.select{ |member| member.has_role?("community_sub_admin", self) }
  end

  # コミュニティの管理人、および副管理人を取得する
  def admin_and_sub_admins
    [self.admin, self.sub_admins].compact.flatten
  end

  # コミュニティの管理者かどうか
  def admin?(user)
    return false unless user
    self.accepts_role?("community_admin", user)
  end

  # コミュニティの副管理人かどうか
  def sub_admin?(user)
    return false unless user
    self.accepts_role?("community_sub_admin", user)
  end

  # コミュニティの一般メンバーかどうか
  def general?(user)
    return false unless user
    self.accepts_role?("community_general", user)
  end

  # コミュニティが開設されてからの日数を返す
  def elapsed_days
    ((Time.now - self.created_at) / 86400).ceil
 end

  #　current_userがmemberの権限に関して操作できるかどうか
  # 条件は、current_userが管理人、または副管理人であり、かつmemberが管理人でなく、
  # current_userとmemberが同一でないとき
  def manageable?(current_user, member)
    (self.admin?(current_user) || self.sub_admin?(current_user)) &&
      !self.admin?(member) && (current_user.id != member.id)
  end

  # トピック、またはマーカーが管理者のみ作成可能かどうか
  def topic_and_marker_createable_admin_only?
    self.topic_createable_admin_only
  end

  # イベントが管理者のみ作成可能かどうか
  def event_createable_admin_only?
    self.event_createable_admin_only
  end

  # current_userがトピック、またはマーカーを作成可能かどうか
  def topic_and_marker_createable?(current_user)
    if current_user && self.member?(current_user)
      if self.admin?(current_user) || self.sub_admin?(current_user)
        return true
      else
        return !self.topic_and_marker_createable_admin_only?
      end
    else
      return false
    end
  end

  # current_userがイベントを作成可能かどうか
  def event_createable?(current_user)
    if current_user && self.member?(current_user)
      if self.admin?(current_user) || self.sub_admin?(current_user)
        return true
      else
        return !self.event_createable_admin_only?
      end
    else
      return false
    end
  end

  # トピック、マーカー、イベントのどれかが作成可能かどうか
  def some_thread_createable?(current_user)
    topic_and_marker_createable?(current_user) || event_createable?(current_user)
  end

  # ユーザが所属する全てのコミュニティのトピック＋そのコメントを取得するためのSQL
  # または、特定のコミュニティのトピック＋そのコメントを取得するためのSQL
  def self.sql_for_comments(user, options={})
    values = []

    community_ids = user.communities.map(&:id)
    community_ids = options[:id] if options[:id] && community_ids.include?(options[:id])

    topic_ids = CommunityTopic.find(:all, :select => "id",
                                    :conditions => ["community_id IN (?)", community_ids]).map(&:id)
    topic_ids = options[:topic_id] if options[:topic_id] && topic_ids.include?(options[:topic_id])

    unless options[:topic_id]
      sql_for_topics = <<-SQL
        SELECT id, 'Topic' AS object_type, title, content, created_at, user_id, NULL AS thread_id, NULL AS thread_type, community_id
        FROM community_threads
        WHERE community_threads.community_id IN (?) AND community_threads.type = 'CommunityTopic'
      SQL
      values += [community_ids]
    end

    sql_for_replies = <<-SQL
      SELECT id, 'Reply' AS object_type, title, content, created_at, user_id, thread_id,  'CommunityTopic' AS thread_type, NULL AS community_id
      FROM community_replies
      WHERE community_replies.thread_id IN (?)
      ORDER BY created_at DESC
    SQL
    values += [topic_ids]

    if options[:topic_id]
     sql = sql_for_replies
    else
      sql = [sql_for_topics, sql_for_replies].join("UNION")
    end
    values.unshift sql
  end

  # あるユーザが所属するコミュニティのトピック、イベント、マーカに対して、最終投稿順でソートして返す
  # ユーザごとのコミュニティ設定で表示しないようにしているものは表示しない
  def self.threads_order_by_post(user, options={})
    cond_s = ["community_id IN (?)"]
    cond_v = [user.news_communities.map(&:id)]

    if options[:days_ago]
      cond_s << "lastposted_at > (?)"
      cond_v << Time.now.advance(:days => -options[:days_ago]).beginning_of_day
    end
    condition = cond_v.unshift(cond_s.join(" AND "))

    CommunityThread.find(:all,
                         :limit => options[:limit],
                         :order => "lastposted_at DESC",
                         :conditions => condition,
                         :include => :community)
  end

  # paginate対応版最新書き込み一覧取得
  def self.threads_order_by_post_paginate(user, options={}, paginate_options = {})
    cond_s = ["community_id IN (?)"]
    cond_v = [user.news_communities.map(&:id)]

    if options[:days_ago]
      cond_s << "lastposted_at > (?)"
      cond_v << Time.now.advance(:days => -options[:days_ago]).beginning_of_day
    end
    condition = cond_v.unshift(cond_s.join(" AND "))

    CommunityThread.paginate(:all,
                             :page => paginate_options[:page].to_i,
                             :per_page => paginate_options[:per_page].to_i,
                             :order => "lastposted_at DESC",
                             :conditions => condition)
  end

  # あるユーザが所属していて、かつ投稿したコメントの中から何日から何日前までのものを取得
  # ==== 引数
  #
  # * user: コメント投稿者
  # * options
  # * <tt>:days_ago</tt> - 何日前までのコメントを取得するか
  # * <tt>:limit</tt> - 最大取得件数
  # * <tt>:vpublic_or_member_visibility</tt> - 外部公開、または全体公開しているコミュニティだけ表示するかどうか
  def self.comments_post(user, options = {})
    limit = options[:limit] || 10
    days_ago = options[:days_ago] || 30

    if options[:vpublic_or_member_visibility]
      visibility_conditions = ["visibility = ? OR visibility = ?",
                               Community::VISIBILITIES[:public], Community::VISIBILITIES[:member]]
    end
    community_ids = user.communities.find(:all,
                                          :conditions => visibility_conditions).map(&:id)

    comments = []

    [CommunityTopic, CommunityEvent, CommunityMarker, CommunityReply].each do |klass|
      cond_s = ["community_id IN (?)"]
      cond_v = [community_ids]

      if klass == CommunityReply
        cond_s << "#{klass.table_name}.deleted = ?"
        cond_v << false
      end

      cond_s << "#{klass.table_name}.user_id = ?"
      cond_v << user.id

      cond_s << "created_at > (?)"
      cond_v << Time.now.advance(:days => -days_ago).beginning_of_day

      condition = cond_v.unshift(cond_s.join(" AND "))
      comments << klass.find(:all,
                             :order => "created_at DESC",
                             :conditions => condition,
                             :include => :community)
    end
    comments.flatten.sort{ |a, b| b.created_at <=> a.created_at }.slice(0, limit)
  end

  # 新着のトピック、イベント、マーカ
  def self.publiced_threads_order_by_post(find_options={})
    threads = []
    ids = self.visibility_is(VISIBILITIES[:public]).map(&:id)
    [CommunityTopic, CommunityEvent, CommunityMarker].each do |klass|
      threads << klass.find(:all,
                            {:order => "lastposted_at DESC",
                            :conditions => ["community_id in (?)", ids]}.
                            merge(find_options))
    end
    threads.flatten!
    limit = find_options[:limit] ? find_options[:limit] : threads.size
    threads.sort{ |a, b| b.lastposted_at <=> a.lastposted_at }.slice(0, limit)
  end

  # コミュニティに紐付く、新着のトピック、イベント、マーカ、それに対するコメント
  def threads_and_comments_order_by_post(limit=nil)
    threads = []
    [CommunityTopic, CommunityEvent, CommunityMarker, CommunityReply].each do |klass|
      cond_s = ["community_id = ?"]
      cond_v = [self.id]

      if klass == CommunityReply
        cond_s << "#{klass.table_name}.deleted = ?"
        cond_v << false
      end

      condition = cond_v.unshift(cond_s.join(" AND "))
      threads << klass.find(:all,
                            {:order => "created_at DESC",
                            :conditions => condition,
                            :limit => limit})
    end
    threads.flatten!
    limit = limit ? limit : threads.size
    threads.sort{ |a, b| b.created_at <=> a.created_at }.slice(0, limit)
  end

  # コミュニティに紐付く、新着のトピック、イベント、マーカ
  def threads_order_by_post(limit=nil, options={})
    days_ago = options[:days_ago] || 30
    threads = []
    [CommunityTopic, CommunityEvent, CommunityMarker].each do |klass|
      threads << klass.find(:all,
                            {:order => "lastposted_at DESC",
                            :conditions => ["community_id = ? AND lastposted_at > ?",
                                            self.id, Time.now.advance(:days => -days_ago).beginning_of_day],
                            :limit => limit})
    end
    threads.flatten!
    limit = limit ? limit : threads.size
    threads.sort{ |a, b| b.lastposted_at <=> a.lastposted_at }.slice(0, limit)
  end

  # show_real_nameが存在するかどうかを返す
  def show_real_name?
    self.show_real_name
  end

  def self.admin_community_topics_search_id_sql(id)
    sql =<<-SQL
      select id ,title, content, user_id, created_at, community_id as community_
id, 'community_topics' as model from community_topics
      where id = ? union all
      select id ,title, content, user_id, created_at, community_id as community_
id, 'community_events' as model from community_events
      where id = ? union all
      select id, title, content, user_id, created_at, community_id as community_
id, 'community_markers' as model from community_markers
      where id = ? union all
      select id, title, content, user_id, created_at, 0 as community_id, 'commun
ity_replies' as model from community_replies
      where id = ?
      order by created_at desc
   SQL
   return [sql, id, id, id, id]
  end

  def self.extraction_of_writing_topics(default_per_page, options = {})
    self.paginate_by_sql(self.admin_community_topics_sql,
      {:per_page => options[:per_page] ? options[:per_page] : default_per_page,
       :page => options[:page] ? options[:page] : 1,
       :order => 'id desc'
      }
    )
  end

  # ユーザー削除時にそのユーザと関係するコミュニティ関連のデータを削除したり、管理権限を委譲したりする
  def self.post_process_after_user_destroyed(user)
    admin_communities = CommunityMembership.admin_communities(user)

    # 管理人であった場合、管理権限の移譲処理などを行う
    admin_communities.each do |admin_community|
      #参加が一番古い副管理人、もしくは参加が一番古い一般メンバーを取得
      new_admin_user = admin_community.get_oldest_role_user("community_sub_admin") ||
                         admin_community.get_oldest_role_user("community_general")
      # 自分以外がメンバーにいた場合
      if new_admin_user
        # 副管理人のコミュニティに対する役目を管理者に設定
        new_admin_user.has_role!("community_admin",admin_community)
        # 作成マップカテゴリを新管理者に委譲
        unless admin_community.map_categories.blank?
          CommunityMapCategory.change_user!(user.id, new_admin_user.id, admin_community.id)
        end
        # 退会ユーザをコミュニティからも退会させる
        admin_community.remove_member!(user)
      #参加者が自分だけの場合コミュニティ削除
      else
        admin_community.destroy
      end
    end

    # 自分がこれまでに書き込んだ返信の削除フラグを立てる
    CommunityReply.update_all("deleted = #{true}",["user_id = ?", user.id])

    # 自分がこれまでに書き込んだスレッドを削除する
    CommunityThread.destroy_all(["user_id = ?", user.id])

    # コミュニティからの退会処理をする
    user.communities.each do |community|
      community.remove_member!(user)
    end
  end

  # 最新書き込みを表示するかどうか
  # コミュニティに所属していなければ、falseを返す
  def new_comment_displayed?(user)
    membership = CommunityMembership.user_id_is(user.id).community_id_is(self.id).first
    membership ? membership.new_comment_displayed? : false
  end

  # 書き込み通知メールを送信するかどうか
  # コミュニティに所属していなければ、falseを返す
  def comment_notice_acceptable?(user)
    membership = CommunityMembership.user_id_is(user.id).community_id_is(self.id).first
    membership ? membership.comment_notice_acceptable? : false
  end

  # 携帯に書き込み通知メールを送信するかどうか
  # コミュニティに所属していなければ、falseを返す
  def comment_notice_acceptable_for_mobile?(user)
    membership = CommunityMembership.user_id_is(user.id).community_id_is(self.id).first

    membership ? membership.comment_notice_acceptable_for_mobile? : false
  end

  # 最新書き込みをの表示設定を変更する
  # コミュニティに参加していないときはfalseを返す
  def change_new_comment_displayed(user)
    membership = CommunityMembership.user_id_is(user.id).community_id_is(self.id).first
    return false if membership.nil?
    membership.update_attributes(:new_comment_displayed => !membership.new_comment_displayed)
  end

  # 書き込み通知メールを送信するかどうかの設定を変更する
  # コミュニティに参加していないときはfalseを返す
  def change_comment_notice_acceptable(user)
    membership = CommunityMembership.user_id_is(user.id).community_id_is(self.id).first
    return false if membership.nil?
    membership.update_attributes(:comment_notice_acceptable => !membership.comment_notice_acceptable)
  end

  # 携帯に書き込み通知メールを送信するかどうかの設定を変更する
  # コミュニティに参加していないときはfalseを返す
  def change_comment_notice_acceptable_for_mobile(user)
    membership = CommunityMembership.user_id_is(user.id).community_id_is(self.id).first
    return false if membership.nil?
    membership.update_attributes(:comment_notice_acceptable_for_mobile => !membership.comment_notice_acceptable_for_mobile)
  end

  # 書き込み通知メールを送信するかどうかの設定を変更する
  # PC、携帯どちらの設定も同時に変更する
  # コミュニティに参加していないときはfalseを返す
  #
  # ==== 引数
  # * attr
  # * <tt>:comment_notice_acceptable</tt> - PCへの通知メールを受け取るか
  # * <tt>:comment_notice_acceptable_for_mobile</tt> - 携帯への通知メールを受け取るか
  def update_comment_notice_acceptable(user, attr)
    membership = CommunityMembership.user_id_is(user.id).community_id_is(self.id).first
    return false if membership.nil?

    attr.stringify_keys!
    valid_keys = %w(comment_notice_acceptable comment_notice_acceptable_for_mobile)
    attr.reject!{ |key, value| !valid_keys.include?(key) }
    membership.update_attributes(attr)
  end

  # ログインしていなくても閲覧できるかどうか
  def anoymous_viewable?
    visibility_public?
  end

  # ログインしていれば閲覧できるかどうか
  def login_user_viewable?
    visibility_public? || visibility_member?
  end

  # コミュニティリンク新着一覧を取得する
  def news_community_linkage(view, limit = 20)
    unsorted_news = self.linkages.map do |linkage|
      linkage.news(view, limit)
    end.flatten

    unsorted_news.sort_by{|hash| hash[:updated_at] }.reverse.slice(0, limit)
  end

  # コミュニティの公認名を返す
  def official_lable
    I18n.t("community.official_label.#{OFFICIALS.invert[self.official]}")
  end

  # メンバーへのメッセージ送信が可能かどうか
  def member_message_senderable?(user)
    return false unless user
    self.member?(user) && (self.official == OFFICIALS[:none] || self.official == OFFICIALS[:normal])
  end

  # 公認コミュニティかどうかを返す
  def official?
    self.official != OFFICIALS[:none]
  end

  # 管理人を勤めていて、かつ承認制のコミュニティの参加依頼をしているユーザを取得する
  def self.all_pending_users(user)
    return PendingCommunityUser.find_by_sql([%Q(select pending_community_users.* from pending_community_users INNER JOIN communities on communities.id = pending_community_users.community_id INNER JOIN roles on roles.name = 'community_admin' and roles.authorizable_type = 'Community' and roles.authorizable_id = communities.id INNER JOIN roles_users ON roles_users.role_id = roles.id WHERE roles_users.user_id  = ? AND communities.approval_required = ? AND pending_community_users.state = ? ORDER BY pending_community_users.created_at DESC), user.id, true, "pending"])
  end

  # コミュニティ参加メンバーから外す
  def remove_member!(user)
    # userがコミュニティグループにselfを含めていたら、削除する
    user.community_groups.each { |cg| cg.remove_community(self) }

    # NOTE: メンバー数のカウンタを正しく動作させるために、destroyメソッドを呼んでいる
    CommunityMembership.community_id_is(self.id).user_id_is(user.id).first.try(:destroy)
    self.pending_users.delete(user)
    user.has_no_roles_for!(self)
  end

  # コミュニティ管理権限を委譲する
  # 公認コミュニティ（管理人）への追加・削除処理も行う
  def delegate_admin_to(user)
    if self.member?(user) && !self.admin?(user)
      admin_member = self.admin
      user.has_no_roles_for!(self)
      user.has_role!("community_admin", self)
      admin_member.has_no_roles_for!(self)
      admin_member.has_role!("community_general", self)

      Community.add_member_to_official_admin_only(user)
      Community.remove_member_from_official_admin_only(admin_member)
    end
  end

  # 実名表示するコミュニティであれば、性・名を表示
  # そうでなければ、通常どおりニックネームを表示
  # ユーザテーブルの実名を出す出さないのフラグは影響しない
  def member_name(user)
    return "" unless user
    return user.name unless self.member?(user)
    self.show_real_name? ? user.full_real_name : user.name
  end

  # 上記メソッドに対して、敬称をつける
  def member_name_with_suffix(user)
    I18n.t("name_suffix", :value => self.member_name(user))
  end

  # 公認コミュニティに対して、参加対象メンバーとなる人を全員参加させる処理
  # 公認コミュニティのタイプによって、内容は変わる
  def add_members_to_official
    case self.official_name
    when :all_member
      # 公認コミュニティ（全員）
      users = User.by_activate_or_by_pending
    when :admin_only
      # 公認コミュニティ（管理人）
      users = Community.all_admin_users
    end

    unless users.blank?
      users.each do |user|
        unless self.member?(user)
          self.members << user
          user.has_role!(:community_general, self)
        end
      end
    end
  end

  # 公認コミュニティ（管理人）にuserを参加させる
  def self.add_member_to_official_admin_only(user)
    Community.find(:all, :conditions => ["official = ?", OFFICIALS[:admin_only]]).each do |c|
      unless c.member?(user)
        c.members << user
        user.has_role!(:community_general, c)
      end
    end
  end

  # userが管理人であるコミュニティが無ければ、公認コミュニティ（管理人）から除外
  def self.remove_member_from_official_admin_only(user)
    unless Community.all_admin_users.map(&:id).include?(user.id)
    Community.find(:all, :conditions => ["official = ?", OFFICIALS[:admin_only]]).each do |c|
        c.remove_member!(user)
      end
    end
  end

  # 管理しているコミュニティの数
  def self.admin_communities_count(user)
    count_by_sql([%Q(select count(*) from communities INNER JOIN roles on roles.name = 'community_admin' and roles.authorizable_type = 'Community' and roles.authorizable_id = communities.id INNER JOIN roles_users ON roles_users.role_id = roles.id WHERE roles_users.user_id = ?), user.id])
  end

  private

  def set_lastposted_at
    self.lastposted_at ||= Time.now
  end

  # 何らかの管理人であるuserを取得
  def self.all_admin_users
    User.find(:all, :include => :roles,
              :conditions => ["users.approval_state = ? AND roles.authorizable_type = ? AND roles.name = ?",
                              "active", "Community", "community_admin"])
  end

  # 公認コミュニティ（全員）にuserを参加させる
  def self.add_member_to_official_all_member(user)
    Community.find(:all, :conditions => ["official = ?", OFFICIALS[:all_member]]).each do |c|
      unless c.member?(user)
        c.members << user
        user.has_role!(:community_general, c)
      end
    end
  end
end

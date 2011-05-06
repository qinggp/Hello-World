# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_threads
#
#  id                        :integer         not null, primary key
#  title                     :string(255)
#  content                   :text
#  event_date                :date
#  event_date_note           :string(255)
#  place                     :string(255)
#  latitude                  :decimal(9, 6)
#  longitude                 :decimal(9, 6)
#  zoom                      :integer
#  user_id                   :integer
#  community_id              :integer
#  public                    :boolean
#  community_map_category_id :integer
#  type                      :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  lastposted_at             :datetime
#

class CommunityEvent < CommunityThread
  has_many :community_event_members, :dependent => :destroy
  has_many :participations, :through => :community_event_members, :source => :user,
           :order => "community_event_members.created_at"

  after_create :add_author_to_event_members

  @@presence_of_columns = [:title, :content, :event_date, :place, :public]
  validates_presence_of @@presence_of_columns.reject{ |item| item == :public}
  validates_inclusion_of :public,  :in => [true, false]

  cattr_reader :presence_of_columns

  PUBLICS = {
    :yes => true,  # 全体に公開
    :no => false,  # コミュニティにのみ公開
  }.freeze

  named_scope :open, lambda {
    { :conditions => ["event_date = ? ", Date.today] }
  }

  named_scope :on_calendar, lambda {
    cond = ["public = ? AND community_id IN (?)", true, Community.not_secret.not_private.map(&:id)]
    { :conditions => cond}
  }

  named_scope :on_calender_for_outer, lambda {
    cond = ["public = ? AND community_id IN (?)", true, Community.public.map(&:id)]
    { :conditions => cond}
  }

  named_scope :by_event_date_on_month, lambda{|year, month|
    date = (year && month) ? Date.new(year, month) : Date.today.beginning_of_month
    {:conditions => ["community_threads.event_date >= ? AND community_threads.event_date < ?", date, date.next_month.beginning_of_month]}
  }

  # イベントを表すアイコンのパスを返す
  def icon_path
    "community/comm_event.gif"
  end

  # コミュニティをイベント数でソートする場合にイベント数をカウントするSQLを返す
  # order by句のサブクエリとして使用する
  def self.sql_for_sort_by_count
    %Q(SELECT count(*) FROM community_threads WHERE communities.id = community_threads.community_id AND community_threads.type = 'CommunityEvent')
  end

  # ユーザがイベント参加者かどうかを返す
  def participations?(user)
    user && self.participations.map(&:id).include?(user.id)
  end

  # ユーザをイベントに参加させる
  # ユーザがコミュニティのメンバーでなければ参加できない
  def participate_in(user)
    self.participations << user if self.community.member?(user)
  end

  # ユーザをイベント参加者から外す
  # イベント作成者は外せない
  def cancel_participation(user)
    self.participations.delete(user) if self.author.id != user.id
  end

  # イベント参加者へのメッセージを送信できるかを返す
  def message_senderable?(user)
    self.community.member?(user) && self.author.id == user.id
  end

  # Viewに渡すセレクトボックスのオプション（イベント公開範囲用）
  def self.select_options_for_publivcs(*keys)
    keys.map do |key|
      [I18n.t("community_event.public")[PUBLICS[key]], PUBLICS[key]]
    end
  end

  private
  # イベント作成時に、イベント参加者に作成者を追加する
  def add_author_to_event_members
    participate_in(self.author)
  end
end

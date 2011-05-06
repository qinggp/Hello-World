# == Schema Information
# Schema version: 20100227074439
#
# Table name: tracks
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  visitor_id :integer
#  page_type  :integer
#  created_at :datetime
#  updated_at :datetime
#

class Track < ActiveRecord::Base

  belongs_to :user
  belongs_to :visitor, :foreign_key => "visitor_id", :class_name => "User"

  after_create :notify_track_count, :if => :notify_track_count?

  named_scope :by_user, lambda { |user|
    {:conditions => ["tracks.user_id = ?", user.id]}
  }

  named_scope :latest, { :limit => 30 }

  # 各訪問者の最新のあしあとのみを取得し、訪問日を降順でソートする
  named_scope :group_by_visitor, lambda {
    {:select => "visitor_id, MAX(created_at) AS created_at",
     :group => "visitor_id", :order => "created_at DESC"}
  }

  # 特定の番号を指定する
  named_scope :specific_number, lambda { |number|
    {:select => "*, #{number} AS number",
      :offset => (number - 1), :limit => 1, :order => "created_at"}
  }

  # あしあとをカウントしたときのページの種類
  PAGE_TYPES = {
    :profile => 1,  # 他のユーザのプロフィールページ
    :friend => 2,   # 他のユーザのトモダチ一覧ページ
  }

  # ブログ機能を取り込んでいる場合、他のユーザのブログページ
  PAGE_TYPES[:blog] = 3  if TrackExtension.instance.extension_enabled?(:blog)

  # コミュニティ機能を取り込んでいる場合、他のユーザのコミュニティ参加一覧ページ
  PAGE_TYPES[:community] = 4 if TrackExtension.instance.extension_enabled?(:community)

  # スケジュール機能を取り込んでいる場合、他のユーザのスケジュールカレンダー
  PAGE_TYPES[:schedule] = 5 if TrackExtension.instance.extension_enabled?(:community)

  PAGE_TYPES.freeze

  # ページの種類が一致するか判定するメソッド
  PAGE_TYPES.each do |label, value|
    define_method("#{label}_page_type?") do
      self.page_type == value
    end
  end

  validates_inclusion_of :page_type, :in => PAGE_TYPES.values

  def validate
    errors.add(:base, "自分のページにあしあとは残せません") if self.user_id == self.visitor_id

    interval = 1800 if  respond_to?(:blog_page_type?) && self.blog_page_type?
    interval ||= 60

    if Track.exists?(["user_id = ? AND visitor_id = ? AND page_type = ? AND created_at > ?",
                      self.user_id, self.visitor_id, self.page_type, Time.now - interval])
      errors.add(:base, "あしあとの間隔が短すぎます")
    end
  end

  # ページの種類を返す。無ければ例外を投げる
  def self.page_type(sym)
    if page_type = PAGE_TYPES[sym]
      return page_type
    else
      raise ArgumentError
    end
  end

  # メンバーにつけられたあしあとを、キリ番ごとに取得する
  # 最大で最新のもの30件まで表示
  def self.split(number, user)
    total_count = self.by_user(user).length
    total_split_count = total_count / number  # キリ番の件数

    loop_count = 0
    array = []

    total_split_count.downto(1) do |i|
      split_number = i * number
      array << self.by_user(user).specific_number(split_number).first
      break if (loop_count += 1) >= 30
    end
    array
  end

  # メンバーにあしあとのメール通知をする
  def notify_track_count
    track_count = self.user.preference.track_preference.notification_track_count
    TrackCountNotifiler.deliver_notification(:track => self, :track_count => track_count)
  end

  # 現在のあしあとの数が設定値と同じであるかどうかを見て、メンバーに通知するかどうかを返す
  def notify_track_count?
    if self.user.preference.track_preference
      self.user.preference.track_preference.notification_track_count == Track.total_count(self.user)
    else
      false
    end
  end

  # メンバーにつけられたあしあとの総数
  def self.total_count(user)
    Track.by_user(user).size
  end

  # あしあとをつけた訪問者の延べ人数
  def self.total_visitor(user)
    Track.count("visitor_id", :distinct => "visitor_id" ,:conditions => ["user_id = ?", user.id])
  end

  # 訪問者が本当に存在しているか
  def visitor_realy_exists?
    User.exists?(self.visitor_id)
  end

  # あしあとの件数がuserにつけられたあしあとの総数範囲内であるかどうか
  def self.range_of_total_count?(user, count)
    total_count = self.total_count(user)
    count > 0 && count <= total_count
  end
end


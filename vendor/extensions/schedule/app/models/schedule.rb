# == Schema Information
# Schema version: 20100227074439
#
# Table name: schedules
#
#  id         :integer         not null, primary key
#  due_date   :date
#  start_time :datetime
#  end_time   :datetime
#  title      :string(255)
#  detail     :text
#  public     :boolean
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

class Schedule < ActiveRecord::Base
  belongs_to :author, :foreign_key => "user_id",  :class_name => "User"

  validates_presence_of :due_date, :title, :detail

  before_save :set_start_time, :if => Proc.new{|s| s.start_time }
  before_save :set_end_time, :if => Proc.new{|s| s.end_time }

  named_scope :by_activate_users, lambda{
    {:conditions => ["schedules.user_id not in (?)", User.by_deactivate.map(&:id)]}
  }

  @@default_index_order = "schedules.created_at DESC"
  cattr_reader :default_index_order

  # ある日のスケジュール一覧を表示する際のSQL文
  # schedule,community_event,userとそれぞれ関連の無いモデルを一度に表示するため、
  # 直接SQLを記述する。
  def self.sql_for_paginate(date, user, current_user)
    values = []
    sql_for_schedule = <<-SQL
      SELECT id, 'Schedule' AS object_type, title, detail, due_date AS date, start_time, end_time, 0 AS community_id , user_id, 1 AS position
      FROM schedules
      WHERE due_date = ? AND schedules.user_id = ? AND (public = ? OR public = ? AND schedules.user_id = ?)
    SQL
    values += [date, user.id, true, false, current_user.id]

    # 誕生日の判定については、通常の月日の比較の他に、閏年の2/29生まれの人であれば、
    # 平年の誕生日を3/1として比較して判定している
    sql_for_user = <<-SQL
      SELECT id, 'User' AS object_type, name AS title, NULL, birthday AS date, NULL AS start_time , NULL, 0, 0, 2 AS position
      FROM users
      WHERE users.birthday_visibility IN (?) AND
        (
         EXTRACT(month FROM users.birthday) = ? AND EXTRACT(day FROM users.birthday) = ?  OR
         EXTRACT(month FROM users.birthday) = 2 AND EXTRACT(day FROM users.birthday) = 29 AND 3 = ? AND 1 = ? AND  ?
        )
        AND users.id IN (?)
    SQL
    values += [current_user.birthday_visibilities_through(user), date.month, date.day,
               date.month, date.day, !date.leap?, user.friends.map(&:id)]

    sql_for_community_event = <<-SQL
      SELECT ev.id AS id, 'CommunityEvent' AS object_type, ev.title AS title,
        ev.content AS title, ev.event_date AS date, NULL AS start_time, NULL, ev.community_id AS community_id, 0, 3 AS position
      FROM (community_threads AS ev LEFT OUTER JOIN community_event_members ON
           ev.id = community_event_members.community_event_id) LEFT OUTER JOIN communities ON
           ev.community_id = communities.id
      WHERE community_event_members.user_id = ? AND ev.event_date = ? AND ev.type = 'CommunityEvent' AND
           communities.visibility NOT IN (?)

    SQL
    values += [user.id, date, [Community::VISIBILITIES[:secret], Community::VISIBILITIES[:private]]]

    sql = [sql_for_schedule, sql_for_user, sql_for_community_event].join("UNION") << " order by position, start_time, id"
    values.unshift sql
  end

  # スケジュールの期間を返す
  def period
    [self.start_time.try(:strftime, "%H:%M"), self.end_time.try(:strftime, "%H:%M")].compact.join("〜")
  end

  # スケジュールを編集可能かどうか
  def editable?(user)
    self.author.id == user.id
  end

  alias_method :destroyable?, :editable?

  private

  # 入力されたスケジュールの開始時間から、日付はdue_dateとし、DateTime型へと変換する
  def set_start_time
    hour, minute =  self.start_time.hour, self.start_time.min
    year, month, day = self.due_date.year, self.due_date.month, self.due_date.day
    self.start_time = "#{year}/#{month}/#{day} #{hour}:#{minute}"
  end

  # 入力されたスケジュールの終了時間から、日付はdue_dateとし、DateTime型へと変換する
  def set_end_time
    hour, minute =  self.end_time.hour, self.end_time.min
    year, month, day = self.due_date.year, self.due_date.month, self.due_date.day
    self.end_time = "#{year}/#{month}/#{day} #{hour}:#{minute}"
  end
end

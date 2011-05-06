# == Schema Information
# Schema version: 20100227074439
#
# Table name: schedule_preferences
#
#  id            :integer         not null, primary key
#  preference_id :integer
#  visibility    :integer
#  created_at    :datetime
#  updated_at    :datetime
#
#
# スケジュール設定
#
# スケジュールを公開する範囲を設定する
class SchedulePreference < ActiveRecord::Base
  belongs_to :preference

  enum_column :visibility, :friend_only, :member_only, :publiced
  attr_accessible :visibility

  protected

  # デフォルト値設定
  def after_initialize
    self.visibility ||= VISIBILITIES[:friend_only]
  end
end

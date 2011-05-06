# == Schema Information
# Schema version: 20100227074439
#
# Table name: track_preferences
#
#  id                       :integer         not null, primary key
#  preference_id            :integer
#  notification_track_count :integer
#  created_at               :datetime
#  updated_at               :datetime
#
#
# あしあと設定
#
# 何件目のあしあとでメンバーにメール通知するかを設定する。
class TrackPreference < ActiveRecord::Base
  belongs_to :preference
  attr_accessible :notification_track_count
end

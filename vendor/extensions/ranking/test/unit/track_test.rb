require File.dirname(__FILE__) + '/../test_helper'

exit unless RankingExtension.instance.extension_enabled?(:track)

class TrackTest < ActiveSupport::TestCase

  # 合計のアクセス数ランキングの取得テスト
  def test_total_access_ranking
    Track.destroy_all

    # 10人のユーザを作成し、あしあとを一件ずつつ増やしていく
    user_numbers = 10
    users = []
    user_numbers.times do |n|
      u = User.make
      users << u
      (n + 1).times do |track_numbers|
        visitor = User.make
        Track.make(:visitor => visitor,
                   :user => u)
      end
    end

    tracks = Track.access_ranking(10)
    assert_equal user_numbers, tracks.length
    users.reverse.each_with_index do |user, index|
      assert_equal user.id, tracks[index].user_id
      assert_equal Track.total_count(user), tracks[index].count.to_i
    end
  end

  # 最近のアクセス数ランキングの取得テスト
  def test_latest_access_ranking
    Track.destroy_all

    # ユーザを作成し、あしあとを3件つける。
    # ただし、1件は去年、1件は昨日、1件は今日
    user = User.make
    Track.make(:user => user, :visitor => User.make, :created_at => Time.now.years_ago(1))
    Track.make(:user => user, :visitor => User.make, :created_at => Time.now.yesterday)
    Track.make(:user => user, :visitor => User.make, :created_at => Time.now)

    # 昨日つけられたあしあとのみをカウント
    tracks = Track.access_ranking(10,
                                  :start_date => Time.now.yesterday.beginning_of_day,
                                  :end_date => Time.now.yesterday.end_of_day)

    assert_equal 1, tracks.length
    assert_equal 1, tracks.first.count.to_i
  end
end

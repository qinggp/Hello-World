require File.dirname(__FILE__) + '/../test_helper'

class TrackTest < ActiveSupport::TestCase

  # メンバーにつけられたあしあとを、キリ番ごとに取得するメソッドのテスト
  def test_split
    user = User.make
    visitor = User.make
    total = 100
    split_number = 2  # キリ番

    assert_difference "Track.count", total do
      total.times do |n|
        track_make(:user_id => user.id, :visitor_id => visitor.id)
      end
    end

    tracks = Track.split(2, user)
    assert_equal 30, tracks.size
    tracks.each_with_index do |track, index|
      assert_equal((total - index * split_number), track.number.to_i)
    end
  end

  # メンバーにつけられたあしあとの総数を計算するメソッドのテスト
  def test_total_count
    user = User.make
    visitor1 = User.make
    visitor2 = User.make

    # ユーザのプロフィールページで3回x2
    3.times do
      track_make(:user_id => user.id, :visitor_id => visitor1.id)
      track_make(:user_id => user.id, :visitor_id => visitor2.id)
    end

    # 関係無い人のページのあしあと一件追加
    track_make(:user_id => User.make.id, :visitor_id => visitor1.id)

    assert_equal 6, Track.total_count(user)
  end

  # 訪問者ごとのあしあとを取得するnamed_scopeのテスト
  def test_group_by_visitor
    user = User.make
    visitor_number = 3
    visitors = Array.new(visitor_number) { User.make }
    interval = 2000

    2.times do
      visitors.each do |v|
        track_make(:user_id => user.id, :visitor_id => v.id, :interval => interval)
      end
    end

    # 訪問者ごとの最新のあしあとが取得できていて、かつあしあとが訪問日の降順でソートされていることを確認
    tracks = Track.by_user(user).group_by_visitor.all
    visitor_number.times do |n|
      assert_equal visitors[visitor_number - (n + 1)].id, tracks[n].visitor.id
      assert_equal((@created_at - n * interval) , tracks[n].created_at)
    end
  end

  # validationが期待通り動作しているかテスト
  def test_validation
    user = User.make
    visitor = User.make

    track_make(:user_id => user.id, :visitor_id => visitor.id)

    # 連続であしあとがつけられないかテスト
    assert_difference "Track.count", 1 do
      Track.make(:user_id => user.id, :visitor_id => visitor.id)
      assert_raise ActiveRecord::RecordInvalid do
        Track.make(:user_id => user.id, :visitor_id => visitor.id)
      end
    end

    # 自分で自分にあしあとがつけられないかテスト
    assert_no_difference "Track.count" do
      assert_raise ActiveRecord::RecordInvalid do
        track_make(:user_id => user.id, :visitor_id => user.id)
      end
    end
  end

  # 訪問者が本当に存在するかどうかを返すメソッドのテスト
  def test_visitor_realy_exists?
    user = User.make
    visitor = User.make

    track = track_make(:user_id => user.id, :visitor_id => visitor.id)
    assert track.visitor_realy_exists?

    visitor.destroy
    assert !track.visitor_realy_exists?
  end

  # ユーザを削除したときのあしあと削除テスト
  def test_destroy_user
    user = User.make
    visitor = User.make

    total = 2
    total.times do |n|
      track_make(:user_id => user.id, :visitor_id => visitor.id)
    end

    # visitorがつけたあしあとは消えない
    # またuserへのあしあと総数は変わらない
    assert_no_difference ["Track.count", "Track.total_count(user)"] do
      visitor.destroy
    end

    # 自分がつけられたあしあとは消える
    assert_difference "Track.count", -total do
      user.destroy
    end
  end

  # あしあとの件数がuserにつけられたあしあとの総数範囲内であるかどうかを返すメソッドのテスト
  def test_range_of_total_count
    user = User.make
    visitor = User.make
    total = 10
    total.times do |n|
      track_make(:user_id => user.id, :visitor_id => visitor.id)
    end

    assert Track.range_of_total_count?(user, 1)
    assert Track.range_of_total_count?(user, 10)
    assert !Track.range_of_total_count?(user, 11)
    assert !Track.range_of_total_count?(user, 0)
  end

  # あしあとをつけた訪問者の延べ人数をカウントするメソッドのテスト
  def test_total_visitor
    user = User.make
    total = 2

    total.times do
      visitor = User.make
      2.times { track_make(:user_id => user.id, :visitor_id => visitor.id) }
    end

    assert_equal total, Track.total_visitor(user)
  end
end

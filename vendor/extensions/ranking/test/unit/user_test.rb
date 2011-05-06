require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    setup_emails
  end

  # トモダチ数の多いメンバーのランキング取得のテスト
  def test_total_friend_count_ranking
    User.destroy_all
    limit = 10

    # ユーザ10人作って、最初のユーザはトモダチなし
    # 次のユーザは1人トモダチ（この1人は最初の10人とは無関係）とやっていく
    user_numbers = 10
    users = []
    user_numbers.times{ users << User.make }
    users.each_with_index do |u, i|
      i.times do
        friend = User.make
        u.friend!(friend)
      end
    end

    rankings = User.friend_count_ranking(limit)

    assert_equal user_numbers, rankings.length
    users.reverse.each_with_index do |u, i|
      # 1人トモダチは複数いるので、飛ばす（誰が入ってくるかわからない）
      next if u.friends.count == 0 || u.friends.count == 1
      assert_equal rankings[i].id, u.id
      assert_equal rankings[i].count.to_i, u.friends.count
    end
  end

  # 最近トモダチが増えたメンバーのランキング取得のテスト
  def test_latest_friend_count_ranking
    User.destroy_all

    # ユーザを一人作り、3人とトモダチを作る
    user = User.make
    3.times { user.friend!(User.make) }

    # 3日前から、今日までのトモダチの数のランキングを取得
    rankings = User.friend_count_ranking(10, :start_date => Time.now.advance(:days => -3).beginning_of_day, :end_date => Time.now.end_of_day)

    assert_equal 4, rankings.length
    assert_equal 3, rankings.first.count.to_i
  end

  # ブログの件数が多いユーザランキング取得のテスト
  def test_total_blog_entry_count_ranking
    # blog extensionが無ければテストは実行しない
    exit unless RankingExtension.instance.extension_enabled?(:blog)
    make_default_blog_category

    BlogEntry.destroy_all

    # ユーザを10人作成して、それぞれに1件、2件とブログを持たせる
    user_numbers = 10
    users = []
    user_numbers.times{ users << User.make }
    users.each_with_index do |user, index|
       (index + 1).times { BlogEntry.make(:user => user) }
    end

    rankings = User.blog_entry_ranking(10)

    assert_equal user_numbers, rankings.length
    users.reverse.each_with_index do |user, index|
      assert_equal BlogEntry.by_user(user).length, rankings[index].count.to_i
      assert_equal user.id, rankings[index].id
    end
  end

  # 招待したユーザの数のランキングを取得
  def test_invitation_count_ranking
    User.destroy_all

    # userを三人作成する
    # AがB,Cを招待し、DがAを招待する
    user_d = User.make
    user_a = User.make(:invitation => user_d)
    user_b = User.make(:invitation => user_a)
    user_c = User.make(:invitation => user_a)

    rankings = User.invitation_count_ranking(10)

    assert_equal 2, rankings.size
    assert_equal user_a.id, rankings.first.id
    assert_equal 2, rankings.first.count
    assert_equal user_d.id, rankings.second.id
    assert_equal 1, rankings.second.count
  end
end

require File.dirname(__FILE__) + '/../test_helper'

exit unless RankingExtension.instance.extension_enabled?(:track)

class CommunityTest < ActiveSupport::TestCase

  # 最近の投稿ランキングの取得テスト
  def test_latest_comments_post_ranking

    Community.destroy_all
    community = Community.make(:community_category => CommunityCategory.make,
                               :participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:member])
    creation_count_for_each = 3

    [CommunityEvent, CommunityTopic, CommunityMarker, CommunityReply].each do |klass|
      creation_count_for_each.times do
        attributes = {:community => community, :created_at => Time.now.yesterday}
        attributes.update(:thread => CommunityTopic.make) if klass == CommunityReply
        klass.make(attributes)
      end
    end

    latest_comments_post =
      Community.comments_post_ranking(10,
                                      :start_date => Time.now.yesterday.beginning_of_day,
                                      :end_date => Time.now.yesterday.end_of_day)

    assert_equal 1, latest_comments_post.length
    assert_equal creation_count_for_each * 4, latest_comments_post.first.count.to_i
    assert_equal community.id, latest_comments_post.first.id
  end

  # 参加者が多いコミュニティのランキング取得のテスト
  def test_total_member_count_ranking
    Community.destroy_all

    limit = 10
    # コミュニティを10件作成して、参加者を1人、2人と増やしていく
    community_numbers = 10
    communities = []
    community = Community.make(:community_category => CommunityCategory.make,
                               :participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:member])

    communities.each_with_index do |c, i|
      (i + 1).times { c.members << User.make}
    end

    rankings = Community.member_count_ranking(limit)

    assert_equal communities.size, rankings.length
    communities.reverse.each_with_index do |c, i|
      assert_equal rankings[i].id, c.id
      assert_equal rankings[i].count.to_i, c.members.count
    end
  end

  # 最近参加者が多いコミュニティランキング取得のテスト
  def test_latest_member_count_ranking
    Community.destroy_all

    # コミュニティを一件作成して、去年、3日前、今日と参加者を増やす
    community = Community.make(:community_category => CommunityCategory.make,
                               :participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:member])

    CommunityMembership.with_options(:community_id => community.id) do |opt|
      opt.create(:user_id => User.make.id, :created_at => Time.now.years_ago(1))
      opt.create(:user_id => User.make.id, :created_at => Time.now.advance(:days => -3))
      opt.create(:user_id => User.make.id, :created_at => Time.now)
    end

    # 3日前から今日までのところで、参加者が増えたコミュニティのランキングを取得
    rankings = Community.member_count_ranking(10, :start_date => Time.now.advance(:days => -3).beginning_of_day, :end_date => Time.now.end_of_day)

    assert_equal 1, rankings.length
    assert_equal 2, rankings.first.count.to_i
  end
end

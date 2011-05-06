require File.dirname(__FILE__) + '/../test_helper'

class CommunityMarkerTest < ActiveSupport::TestCase
  def setup
    @community = Community.make
    @marker = CommunityMarker.make(:community => @community)
  end

  # マーからからトピックになるメソッドのテスト
  def test_become_topic
    assert_difference "CommunityTopic.count" do
      assert_difference "CommunityMarker.count", -1 do
        @marker.become_topic!
      end
    end

    topic = CommunityTopic.find @marker.id
    assert_equal "CommunityTopic", topic.kind
    assert_nil topic.community_map_category_id
    assert_nil topic.latitude
    assert_nil topic.longitude
    assert_nil topic.zoom

  # コミュニティから見たときのマーカーの数、及びトピックの数が変化するか
    @community.reload
    assert_equal 0, @community.markers_count
    assert_equal 1, @community.topics_count
  end

  # マーカー作成・削除時に対応するカラムの数が変動するか
  def test_marker_count
    community = Community.make
    assert_equal 0, community.markers_count

    event = CommunityMarker.make(:community_id => community.id)
    community.reload
    assert_equal 1, community.markers_count

    event.destroy
    community.reload
    assert_equal 0, community.markers_count
  end
end

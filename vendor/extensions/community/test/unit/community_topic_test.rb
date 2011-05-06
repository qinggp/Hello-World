require File.dirname(__FILE__) + '/../test_helper'

class CommunityTopicTest < ActiveSupport::TestCase

  # トピック作成・削除時に対応するカラムの数が変動するか
  def test_topics_count
    community = Community.make
    assert_equal 0, community.topics_count

    topic = CommunityTopic.make(:community_id => community.id)
    community.reload
    assert_equal 1, community.topics_count

    topic.destroy
    community.reload
    assert_equal 0, community.topics_count
  end
end

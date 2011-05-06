require File.dirname(__FILE__) + '/../test_helper'

class CommunityMapCategoryTest < ActiveSupport::TestCase
  def setup
    @community = Community.make
    @map_category = CommunityMapCategory.make(:community => @community)
  end

  # 削除されたとき、所属しているマーカーがトピックへ変わることを確認する
  def test_change_marker_to_topic
    marker_numbers = 2

    markers = Array.new(marker_numbers){ CommunityMarker.make(:map_category => @map_category) }

    assert_difference "CommunityTopic.count", marker_numbers do
      assert_difference "CommunityMarker.count", -marker_numbers do
        @map_category.destroy
      end
    end
  end
end

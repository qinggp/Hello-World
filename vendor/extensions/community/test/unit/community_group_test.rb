require File.dirname(__FILE__) + '/../test_helper'

class CommunityGroupTest < ActiveSupport::TestCase
  # グループにコミュニティが属しているかどうかを返すメソッドのテスト
  def test_has_community
    community = Community.make
    community_group = CommunityGroup.make
    assert !community_group.has_community?(community)

    community_group.communities << community
    assert community_group.has_community?(community)
  end

  # グループにコミュニティを追加するメソッドのテスト
  def test_add_community
    @current_user = User.make
    community = set_community_and_has_role
    community_group = CommunityGroup.make(:user => @current_user)

    assert_difference "CommunityGroupMembership.count" do
      assert community_group.add_community(community)
    end

    assert_equal community.id, community_group.communities.first.id

    # 既にグループに含まれている場合は追加できない
    assert_no_difference "GroupMembership.count" do
      assert !community_group.add_community(community)
    end

    # 参加していないコミュニティは追加できない
    assert_no_difference "GroupMembership.count" do
      assert !community_group.add_community(Community.make)
    end    
  end

  # コミュニティをグループから削除するメソッドのテスト
  def test_remove_community
    @current_user = User.make
    community = set_community_and_has_role
    community_group = CommunityGroup.make(:user => @current_user)
    community_group.add_community(community)

    assert_difference "CommunityGroupMembership.count", -1 do
      assert community_group.remove_community(community)
    end

    # 既に削除されているコミュニティを削除はできない
    assert_no_difference "GroupMembership.count" do
      assert !community_group.remove_community(community)
    end

    # 参加していないコミュニティは削除できない
    assert_no_difference "GroupMembership.count" do
      assert !community_group.remove_community(Community.make)
    end
  end
end

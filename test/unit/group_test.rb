require File.dirname(__FILE__) + '/../test_helper'

class GroupTest < ActiveSupport::TestCase
  # トモダチがグループに含まれているかどうかを返すメソッドのテスト
  def test_group_meber
    group_owner = User.make
    friend = User.make
    group_owner.friend!(friend)
    group = Group.make(:user => group_owner)

    assert !group.group_member?(friend)

    group.add_friend(friend)
    assert group.group_member?(friend)
  end

  # トモダチをグループメンバーに追加するメソッドのテスト
  def test_add_friend
    group_owner = User.make
    friend = User.make
    group_owner.friend!(friend)
    group = Group.make(:user => group_owner)

    assert_difference "GroupMembership.count" do
      assert group.add_friend(friend)
    end

    assert_equal friend.id, group.friends.first.id

    # 既にグループに含まれている場合は追加できない
    assert_no_difference "GroupMembership.count" do
      assert !group.add_friend(friend)
    end

    # トモダチじゃない人は追加できない
    assert_no_difference "GroupMembership.count" do
      assert !group.add_friend(User.make)
    end
  end

  # トモダチをグループから削除するメソッドのテスト
  def test_remove_friend
    group_owner = User.make
    friend = User.make
    group_owner.friend!(friend)
    group = Group.make(:user => group_owner)
    group.add_friend(friend)

    assert_difference "GroupMembership.count", -1 do
      assert group.remove_friend(friend)
    end

    # 既に削除されている人を削除はできない
    assert_no_difference "GroupMembership.count" do
      assert !group.remove_friend(friend)
    end

    # トモダチじゃない人は削除できない
    assert_no_difference "GroupMembership.count" do
      assert !group.remove_friend(User.make)
    end
  end

  # ユーザを削除したときに呼ばれる削除メソッドのテスト
  def test_destroy_related_to_user_record
    user = User.make
    group = nil
    group_count = Group.count
    group_member_count = GroupMembership.count
    3.times do
      group = Group.make(:user_id => user.id)
      3.times do
        GroupMembership.make(:group_id => group.id, :user_id => User.make.id)
      end
      GroupMembership.make(:group_id => group.id, :user_id => user.id)
    end
    other = User.make
    group = Group.make(:user_id => other.id)
    GroupMembership.make(:group_id => group.id, :user_id => other.id)
    assert_equal group_count + 4, Group.count
    assert_equal group_member_count + 13, GroupMembership.count
    user.destroy
    assert_equal group_count + 1, Group.count
    assert_equal group_member_count + 1, GroupMembership.count
  end
end

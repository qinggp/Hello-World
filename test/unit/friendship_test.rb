require File.dirname(__FILE__) + '/../test_helper'

class FriendshipTest < ActiveSupport::TestCase

  # 紹介文を削除し、関係の深さと接触の頻度をデフォルト値に設定するメソッドのテスト
  def test_clear_description
    friendship =
      Friendship.make(:description => "紹介文",
                      :relation => Friendship::RELATIONS[:peer],
                      :contact_frequency => Friendship::CONTACT_FREQUENCIES[:many])

    friendship.clear_description!

    assert_equal nil, friendship.description
    assert_equal Friendship::RELATIONS[:nothing], friendship.relation
    assert_equal Friendship::CONTACT_FREQUENCIES[:nothing], friendship.contact_frequency
  end

  # 紹介文作成時に使用する検証メソッドのテスト
  # descriptionが空のときにひっかかる
  def test_valid_for_request_new_name
    friendship = Friendship.make

    assert friendship.valid?
    assert !friendship.valid_for_edit_description?
  end

  # ユーザを削除したときに呼ばれる削除メソッドのテスト
  def test_destroy_related_to_user_record
    friend_count = Friendship.count
    user = User.make
    friend = User.make
    another_user = User.make
    Friendship.make(:user_id => user.id, :friend_id => friend.id)
    Friendship.make(:user_id => user.id, :friend_id => another_user.id)
    Friendship.make(:user_id => friend.id, :friend_id => another_user.id)
    assert_equal friend_count + 3, Friendship.count
    user.destroy
    assert_equal friend_count + 1, Friendship.count
  end

  # 同じ相手に、2回トモダチ依頼を出せないことを確認する
  def test_valid_for_friend_request_only_once
    user = User.make
    friend = User.make

    assert_difference "Friendship.count" do
      Friendship.make(:user => user, :friend => friend)
    end

    assert_raise ActiveRecord::RecordInvalid do
      assert_no_difference "Friendship.count" do
        Friendship.make(:user => user, :friend => friend)
      end
    end
  end
end

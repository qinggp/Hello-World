require File.dirname(__FILE__) + '/../test_helper'

class CommunityThreadTest < ActiveSupport::TestCase

  def setup
    @user = User.make
    @community = Community.make
    @thread = CommunityTopic.make(:community => @community)
  end

  # 編集できるかどうかを返すメソッドのテスト
  def test_editable
    # 全く関係無い場合
    assert !@thread.editable?(@user)

    # ただの参加者である場合
    @community.members << @user
    @user.has_role!("community_general", @community)
    assert !@thread.editable?(@user)


    # 副管理人である場合
    @user.has_no_roles_for!(@community)
    @user.has_role!("community_sub_admin", @community)
    assert @thread.editable?(@user)


    # 管理人である場合
    @user.has_no_roles_for!(@community)
    @user.has_role!("community_admin", @community)
    assert @thread.editable?(@user)

    # 自分が作成した場合
    @user.has_no_roles_for!(@community)
    @user.has_role!("community_general", @community)
    @thread = CommunityTopic.make(:community => @community,
                                   :author => @user)
    assert @thread.editable?(@user)
  end

  # 作成されたとき、自身のlastposted_atと参照先のコミュニティのlastposted_atが更新されることを確認する
  def test_save_lastposted_at
    stub(Time).now{ Time.local(2020, 10, 10, 10, 10, 10) }

    assert_not_equal @community.reload.lastposted_at, Time.now
    assert_not_equal @thread.reload.lastposted_at, Time.now

    new_thread = CommunityTopic.make(:community => @community)
    assert_equal Time.now, new_thread.reload.lastposted_at
    assert_equal Time.now, @community.reload.lastposted_at
  end

  # スレッド削除（ここではトピックを削除する）
  def test_thread_destroy
    community = set_community_and_has_role(User.make)
    thread = CommunityTopic.make
    reply = CommunityReply.make(:thread => thread, :community => community)
    CommunityThreadAttachment.make(:thread => thread)
    CommunityReplyAttachment.make(:reply => reply)
    thread.reload

    assert_not_nil CommunityReply.find_by_thread_id(thread.id)
    assert_not_nil CommunityThreadAttachment.find_by_thread_id(thread.id)
    assert_not_nil CommunityReplyAttachment.find_by_community_reply_id(reply.id)

    thread.destroy
    assert_nil CommunityReply.find_by_thread_id(thread.id)
    assert_nil CommunityThreadAttachment.find_by_thread_id(thread.id)
    assert_nil CommunityReplyAttachment.find_by_community_reply_id(reply.id)
  end
end

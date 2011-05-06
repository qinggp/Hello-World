require File.dirname(__FILE__) + '/../test_helper'

class CommunityMembershipTest < ActiveSupport::TestCase
  # 最新書き込みを表示するかどうかを返すメソッドのテスト
  def test_new_comment_displayed
    # コミュニティに参加していないのでfalse
    assert !Community.make.new_comment_displayed?(User.make)

    # デフォルトはtrue
    @current_user = User.make
    community = set_community_and_has_role
    assert community.new_comment_displayed?(@current_user)

    m = CommunityMembership.find(:first, ["user_id = ? AND community_id = ?",
                                          @current_user.id, community.id])
    m.update_attributes!(:new_comment_displayed => true)

    assert community.new_comment_displayed?(@current_user)
  end

  # 書き込み通知メールを送信するかどうかを返すメソッドのテスト
  def test_comment_notice_acceptable
    # コミュニティに参加していないのでfalse
    assert !Community.make.comment_notice_acceptable?(User.make)

    # デフォルトはfalse
    @current_user = User.make
    community = set_community_and_has_role
    assert !community.comment_notice_acceptable?(@current_user)

    community.change_comment_notice_acceptable(@current_user)
    assert community.comment_notice_acceptable?(@current_user)
  end

  # 最新書き込みをの表示設定を変更するメソッドのテスト
  def test_change_new_comment_displayed
    @current_user = User.make
    community = set_community_and_has_role

    # デフォルトはtrue
    assert community.new_comment_displayed?(@current_user)

    community.change_new_comment_displayed(@current_user)
    assert !community.new_comment_displayed?(@current_user)

    community.change_new_comment_displayed(@current_user)
    assert community.new_comment_displayed?(@current_user)
  end

  # 書き込み通知メールを送信するかどうかの設定を変更する
  def test_change_comment_notice_acceptable
    @current_user = User.make
    community = set_community_and_has_role

    # デフォルトはfalse
    assert !community.comment_notice_acceptable?(@current_user)

    community.change_comment_notice_acceptable(@current_user)
    assert community.comment_notice_acceptable?(@current_user)

    community.change_comment_notice_acceptable(@current_user)
    assert !community.comment_notice_acceptable?(@current_user)
  end

  # 携帯に書き込み通知メールを送信するかどうかを返すメソッドのテスト
  def test_comment_notice_acceptable_for_mobile
    # コミュニティに参加していないのでfalse
    assert !Community.make.comment_notice_acceptable_for_mobile?(User.make)

    # デフォルトはfalse
    @current_user = User.make
    community = set_community_and_has_role
    assert !community.comment_notice_acceptable_for_mobile?(@current_user)

    community.change_comment_notice_acceptable_for_mobile(@current_user)
    assert community.comment_notice_acceptable_for_mobile?(@current_user)
  end

  # 携帯に書き込み通知メールを送信するかどうかの設定を変更する
  def test_change_comment_notice_acceptable_for_mobile
    @current_user = User.make
    community = set_community_and_has_role

    # デフォルトはfalse
    assert !community.comment_notice_acceptable_for_mobile?(@current_user)

    community.change_comment_notice_acceptable_for_mobile(@current_user)
    assert community.comment_notice_acceptable_for_mobile?(@current_user)

    community.change_comment_notice_acceptable_for_mobile(@current_user)
    assert !community.comment_notice_acceptable_for_mobile?(@current_user)
  end

  # 管理者権限を持つコミュニティを取得するメソッドのテスト
  def test_admin_communities
    user = User.make
    admin_community = set_community_and_has_role(user)
    sub_admin_community = set_community_and_has_role(user, "community_sub_admin")
    general_community = set_community_and_has_role(user, "community_general")

    assert_equal 1, CommunityMembership.admin_communities(user).size
    assert_equal admin_community.id, CommunityMembership.admin_communities(user).first.id
  end

  # メンバーが増えたとき、減ったときにmembers_countが更新されるかテスト
  def test_members_count
    community = set_community_and_has_role(User.make)
    community.reload
    assert_equal 1, community.members_count

    member = User.make
    community.members << member
    community.reload
    assert_equal 2, community.members_count

    community.remove_member!(member)
    community.reload
    assert_equal 1, community.members_count
  end
end

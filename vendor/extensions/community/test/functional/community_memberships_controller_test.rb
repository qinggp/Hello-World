require File.dirname(__FILE__) + '/../test_helper'

class CommunityMembershipsControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
  end

  # 参加コミュニティ一覧画面
  def test_index
    get :index
    
    assert_response :success
    assert_template 'community_memberships/index'
  end

  # 最新書き込みの表示設定変更
  def test_change_new_comment_displayed
    community = set_community_and_has_role
    assert community.new_comment_displayed?(@current_user)

    get :change_new_comment_displayed, :id => community.id

    assert !community.new_comment_displayed?(@current_user)
    assert_response :redirect
    assert_redirected_to community_memberships_path
  end

  # 最新書き込みの表示設定変更失敗
  def test_fail_to_change_new_comment_displayed
    get :change_new_comment_displayed, :id => Community.make.id

    assert_equal "最新書き込みの表示設定変更に失敗しました", flash[:error]
    assert_response :redirect
    assert_redirected_to community_memberships_path
  end

  # 書き込み通知メール送信設定を変更
  def test_change_comment_notice_acceptable
    community = set_community_and_has_role
    assert !community.comment_notice_acceptable?(@current_user)

    get :change_comment_notice_acceptable, :id => community.id

    assert community.comment_notice_acceptable?(@current_user)
    assert_response :redirect
    assert_redirected_to community_memberships_path
  end

  # 書き込み通知メール送信設定変更の失敗
  def test_fail_to_change_comment_notice_acceptable
    get :change_comment_notice_acceptable, :id => Community.make.id

    assert_equal "書き込み通知メールの送信設定変更に失敗しました", flash[:error]
    assert_response :redirect
    assert_redirected_to community_memberships_path
  end

  # 携帯への書き込み通知メール送信設定を変更
  def test_change_comment_notice_acceptable_for_mobile
    community = set_community_and_has_role
    assert !community.comment_notice_acceptable_for_mobile?(@current_user)

    get :change_comment_notice_acceptable_for_mobile, :id => community.id

    assert community.comment_notice_acceptable_for_mobile?(@current_user)
    assert_response :redirect
    assert_redirected_to community_memberships_path
  end

  # 携帯への書き込み通知メール送信設定変更の失敗
  def test_fail_to_change_comment_notice_acceptable_for_mobile
    get :change_comment_notice_acceptable_for_mobile, :id => Community.make.id

    assert_equal "書き込み通知メールの送信設定変更に失敗しました", flash[:error]
    assert_response :redirect
    assert_redirected_to community_memberships_path
  end
end

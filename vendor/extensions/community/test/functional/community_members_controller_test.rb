require File.dirname(__FILE__) + '/../test_helper'

# コミュニティメンバー管理機能テスト
class CommunityMembersControllerTest < ActionController::TestCase

  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # コミュニティの参加メンバー一覧画面
  def test_index
    community = set_community_and_has_role

    get :index, :community_id => community.id

    assert_response :success
  end

  # 副管理人を解任させる
  def test_remove_from_sub_admin
    community = set_community_and_has_role
    member = takes_part_in_community(community, "community_sub_admin")

    get :remove_from_sub_admin, :id => member.id,
        :community_id => community.id

    assert_response :redirect
    assert_redirected_to community_members_path(:community_id => community.id)

    assert !member.has_role?("community_sub_admin", community)
    assert member.has_role?("community_general", community)
  end

  # 副管理人に任命する
  def test_assign_sub_admin_with
    community = set_community_and_has_role
    member = takes_part_in_community(community)

    get :assign_sub_admin_with, :id => member.id,
        :community_id => community.id

    assert_response :redirect
    assert_redirected_to community_members_path(:community_id => community.id)

    assert !member.has_role?("community_general", community)
    assert member.has_role?("community_sub_admin", community)
  end

  # 一般権限の人に管理人権限を委譲する
  def test_delegate_admin_to_general_member
    community = set_community_and_has_role
    member = takes_part_in_community(community)

    get :delegate_admin_to, :id => member.id,
        :community_id => community.id

    assert_response :redirect
    assert_redirected_to community_path(community.id)

    assert !member.has_role?("community_general", community)
    assert member.has_role?("community_admin", community)
    assert !@current_user.has_role?("community_admin", community)
    assert @current_user.has_role?("community_general", community)
  end

  # 副管理人に管理人権限を委譲する
  def test_delegate_admin_to_sub_admin_member
    community = set_community_and_has_role
    member = takes_part_in_community(community, "community_sub_admin")

    get :delegate_admin_to, :id => member.id,
        :community_id => community.id

    assert_response :redirect
    assert_redirected_to community_path(community.id)

    assert !member.has_role?("community_sub_admin", community)
    assert member.has_role?("community_admin", community)
    assert !@current_user.has_role?("community_admin", community)
    assert @current_user.has_role?("community_general", community)
  end

  # 強制退会させる
  def test_dismiss
    community = set_community_and_has_role
    member = takes_part_in_community(community)

    assert_difference "CommunityMembership.count", -1 do
      get :dismiss, :id => member.id, :community_id => community.id
    end

    assert_response :redirect
    assert_redirected_to community_members_path(:community_id => community.id)

    assert !member.has_roles_for?(community)
    assert !community.member?(member)
  end

  # 副管理人が強制退会させる
  def test_sub_admin_dismiss
    community = set_community_and_has_role
    member = takes_part_in_community(community, "sub_admin")

    assert_difference "CommunityMembership.count", -1 do
      get :dismiss, :id => member.id, :community_id => community.id
    end

    assert_response :redirect
    assert_redirected_to community_members_path(:community_id => community.id)

    assert !member.has_roles_for?(community)
    assert !community.member?(member)
  end

  # 管理人を強制退会させることができない
  def test_dismiss_admin
    community = set_community_and_has_role("community_sub_admin")
    member = takes_part_in_community(community, "community_admin")

    assert_no_difference "CommunityMembership.count" do
      get :dismiss, :id => member.id, :community_id => community.id
    end

    assert_response :redirect
    assert_redirected_to community_members_path(:community_id => community.id)

    assert member.has_role?("community_admin", community)
  end

  # ログアウトしている状態で全てのアクションへのアクセスチェック
  def test_access_check_without_login
    logout

    assert_raise Acl9::AccessDenied do
      get :index
    end

    community = Community.make
    member = takes_part_in_community(community)

    actions =
      [:remove_from_sub_admin, :assign_sub_admin_with,
       :delegate_admin_to, :dismiss]
    actions.each do |action|
      assert_raise Acl9::AccessDenied do
        get action, :id => community.id, :member_id => member.id
      end
    end
  end

  # 一般権限で全てのアクションへのアクセスチェック
  def test_access_check_with_general_authority
    community = set_community_and_has_role("community_general")
    member = takes_part_in_community(community)

    assert_raise Acl9::AccessDenied do
      get :index
    end

    actions =
      [:remove_from_sub_admin, :assign_sub_admin_with,
       :delegate_admin_to, :dismiss]
    actions.each do |action|
      assert_raise Acl9::AccessDenied do
        get action, :id => community.id, :member_id => member.id
      end
    end
  end

  # 副管理人権限で、indexとdismissアクション以外へのアクセスチェック
  def test_access_check_with_sub_admin_authority
    community = set_community_and_has_role("community_sub_admin")
    member = takes_part_in_community(community)

    actions =
      [:remove_from_sub_admin, :assign_sub_admin_with,
       :delegate_admin_to]
    actions.each do |action|
      assert_raise Acl9::AccessDenied do
        get action, :id => community.id, :member_id => member.id
      end
    end
  end

  private

  def takes_part_in_community(community, role = "community_general")
    user = User.make
    community.members << user
    user.has_role!(role, community)
    user
  end
end

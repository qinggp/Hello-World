require File.dirname(__FILE__) + '/../test_helper'

# コミュニティグループ管理テスト
class CommunityGroupsControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
  end

  # 登録画面の表示
  def test_new
    get :new

    assert_response :success
    assert_template 'community_groups/form'
    assert_kind_of CommunityGroup, assigns(:community_group)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    assert_no_difference(['CommunityGroup.count']) do
      post :confirm_before_create, :community_group => CommunityGroup.plan
    end

    assert_response :success
    assert_template 'community_groups/confirm'
    assert_equal true, assigns(:community_group).valid?
  end

  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    assert_no_difference(['CommunityGroup.count']) do
      post :confirm_before_create, :community_group => CommunityGroup.plan(:name => "")
    end

    assert_response :success
    assert_template 'community_groups/form'
    assert_equal false, assigns(:community_group).valid?
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    post :confirm_before_create, :community_group => {}, :clear => "Clear"

    assert_response :redirect
    assert_redirected_to new_community_group_path
  end

  # 登録データの作成
  def test_create_community_group
    assert_difference(['CommunityGroup.count']) do
      post :create, :community_group => CommunityGroup.plan
    end

    @community_group = CommunityGroup.last

    assert_redirected_to complete_after_create_community_group_path(@community_group)
  end

  # 登録データの作成キャンセル
  def test_create_community_group_cancel
    assert_no_difference(['CommunityGroup.count']) do
      post :create, :community_group => CommunityGroup.plan, :cancel => "Cancel"
    end

    assert_not_nil assigns(:community_group)
    assert_template 'community_groups/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_community_group_fail
    assert_no_difference(['CommunityGroup.count']) do
      post :create, :community_group => CommunityGroup.plan(:name => "")
    end

    assert_template 'community_groups/form'
  end

  # 編集画面の表示
  def test_edit
    get :edit, :id => CommunityGroup.make(:user => @current_user).id

    assert_response :success
    assert_template 'community_groups/form'
    assert_kind_of CommunityGroup, assigns(:community_group)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    post(:confirm_before_update, :id => CommunityGroup.make(:user => @current_user).id,
        :community_group => CommunityGroup.plan)

    assert_response :success
    assert_template 'community_groups/confirm'
    assert_equal true, assigns(:community_group).valid?
  end

  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    post(:confirm_before_update, :id => CommunityGroup.make(:user => @current_user).id,
        :community_group => CommunityGroup.plan(:name => "" ))

    assert_response :success
    assert_template 'community_groups/form'
    assert_equal false, assigns(:community_group).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    entry = CommunityGroup.make(:user => @current_user)
    post(:confirm_before_update, :id => entry.id,
        :community_group => CommunityGroup.plan,
        :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_community_group_path(entry)
  end

  # 編集データの更新
  def test_update_community_group
    record = CommunityGroup.make(:user => @current_user)

    assert_no_difference(['CommunityGroup.count']) do
      put :update, :id => record.id, :community_group => {:name => CommunityGroup.plan[:name]}
    end

    community_group = assigns(:community_group)
    assert_equal record.name, community_group.name
    assert_equal @current_user.id, community_group.user_id
    assert_redirected_to complete_after_update_community_group_path(community_group)
  end

  # 編集データの作成キャンセル
  def test_update_community_group_cancel
    record = CommunityGroup.make(:user => @current_user)

    put :update, :id => record.id, :community_group => CommunityGroup.plan, :cancel => "Cancel"

    assert_not_nil assigns(:community_group)
    assert_template 'community_groups/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_community_group_fail
    record = CommunityGroup.make(:user => @current_user)

    put :update, :id => record.id, :community_group => CommunityGroup.plan(:name => "")

    expected_name = record.name
    record.reload
    assert_equal expected_name, record.name

    assert_template 'community_groups/form'
  end

  # レコードの削除
  def test_destroy_community_group
    target_id = CommunityGroup.make(:user => @current_user).id
    assert_difference('CommunityGroup.count', -1) do
      delete :destroy, :id => target_id
    end

    assert_redirected_to new_community_group_path
  end

  # 自分が作ったグループでなければ、編集できない
  def test_deny_to_edit_without_own_groups
    group = CommunityGroup.make

    assert_raise Acl9::AccessDenied do
      get :edit, :id => group.id
    end

    assert_raise Acl9::AccessDenied do
      post :confirm_before_update, :id => group.id, :community_group => Group.plan
    end

    assert_raise Acl9::AccessDenied do
      put :update, :id => group.id, :community_group => Group.plan
    end

    assert_raise Acl9::AccessDenied do
      put :complete_after_update, :id => group.id, :community_group => Group.plan
    end
  end

  # 自分が作ったグループでなければ、削除できない
  def test_deny_to_destroy_without_own_groups
    group = CommunityGroup.make

    assert_raise Acl9::AccessDenied do
      delete :destroy, :id => group.id
    end
  end

  # コミュニティグループ管理画面の表示
  def test_community_list
    get :community_list, :id => CommunityGroup.make(:user => @current_user).id

    assert_response :success
    assert_template "community_groups/community_list"
  end

    # グループにコミュニティを追加
  def test_add_community
    community_group = CommunityGroup.make(:user => @current_user)
    community = set_community_and_has_role

    assert_difference "CommunityGroupMembership.count" do
      get :add_community, :id => community_group.id, :community_id => community.id
    end

    assert_equal community.id, community_group.communities.first.id

    assert_response :redirect
    assert_redirected_to community_list_community_group_path(community_group)
  end

  # グループからコミュニティを削除
  def test_remove_community
    community_group = CommunityGroup.make(:user => @current_user)
    community = set_community_and_has_role
    community_group.communities << community

    assert_difference "CommunityGroupMembership.count", -1 do
      get :remove_community, :id => community_group.id, :community_id => community.id
    end

    assert_equal 0, community_group.communities.count

    assert_response :redirect
    assert_redirected_to community_list_community_group_path(community_group)
  end
end

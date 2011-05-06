require File.dirname(__FILE__) + '/../test_helper'

# グループ管理テスト
class GroupsControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
  end

  # 登録画面の表示
  def test_new
    get :new

    assert_response :success
    assert_template 'groups/form'
    assert_kind_of Group, assigns(:group)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    assert_no_difference(['Group.count']) do
      post :confirm_before_create, :group => Group.plan
    end

    assert_response :success
    assert_template 'groups/confirm'
    assert_equal true, assigns(:group).valid?
  end

  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    assert_no_difference(['Group.count']) do
      post :confirm_before_create, :group => Group.plan(:name => "")
    end

    assert_response :success
    assert_template 'groups/form'
    assert_equal false, assigns(:group).valid?
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    post :confirm_before_create, :group => {}, :clear => "Clear"

    assert_response :redirect
    assert_redirected_to new_group_path
  end

  # 登録データの作成
  def test_create_group
    assert_difference(['Group.count']) do
      post :create, :group => Group.plan
    end

    group = assigns(:group)
    assert_equal Group.plan[:name], group.name
    assert_equal @current_user.id, group.user.id

    assert_redirected_to complete_after_create_group_path(group)
  end

  # 登録データの作成キャンセル
  def test_create_group_cancel
    assert_no_difference(['Group.count']) do
      post :create, :group => Group.plan, :cancel => "Cancel"
    end

    assert_not_nil assigns(:group)
    assert_template 'groups/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_group_fail
    assert_no_difference(['Group.count']) do
      post :create, :group => Group.plan(:name => "")
    end

    assert_template 'groups/form'
  end

  # 編集画面の表示
  def test_edit
    get :edit, :id => Group.make(:user => @current_user).id

    assert_response :success
    assert_template 'groups/form'
    assert_kind_of Group, assigns(:group)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    post(:confirm_before_update, :id => Group.make(:user => @current_user).id,
         :group => Group.plan)

    assert_response :success
    assert_template 'groups/confirm'
    assert_equal true, assigns(:group).valid?
  end

  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    post(:confirm_before_update, :id => Group.make(:user => @current_user).id,
        :group => Group.plan(:name => ""))

    assert_response :success
    assert_template 'groups/form'
    assert_equal false, assigns(:group).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    entry = Group.make(:user => @current_user)
    post(:confirm_before_update, :id => entry.id,
        :group => Group.plan,
        :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_group_path(entry)
  end

  # 編集データの更新
  def test_update_group
    record = Group.make(:user => @current_user)

    assert_no_difference(['Group.count']) do
      put :update, :id => record.id, :group => Group.plan
    end

    group = assigns(:group)
    assert_equal record.name, group.name
    assert_equal @current_user.id, group.user_id

    assert_redirected_to complete_after_update_group_path(group)
  end

  # 編集データの作成キャンセル
  def test_update_group_cancel
    record = Group.make(:user => @current_user)

    put :update, :id => record.id, :group => Group.plan, :cancel => "Cancel"

    assert_not_nil assigns(:group)
    assert_template 'groups/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_group_fail
    record = Group.make(:user => @current_user)

    put :update, :id => record.id, :group => Group.plan(:name => "")

    expected_name = record.name
    record.reload
    assert_equal expected_name, record.name

    assert_template 'groups/form'
  end

  # レコードの削除
  def test_destroy_group
    target_id = Group.make(:user => @current_user).id
    assert_difference('Group.count', -1) do
      delete :destroy, :id => target_id
    end

    assert_redirected_to new_group_path
  end

  # 自分が作ったグループでなければ、編集できない
  def test_deny_to_edit_without_own_groups
    group = Group.make

    assert_raise Acl9::AccessDenied do
      get :edit, :id => group.id
    end

    assert_raise Acl9::AccessDenied do
      post :confirm_before_update, :id => group.id, :group => Group.plan
    end

    assert_raise Acl9::AccessDenied do
      put :update, :id => group.id, :group => Group.plan
    end

    assert_raise Acl9::AccessDenied do
      put :complete_after_update, :id => group.id, :group => Group.plan
    end
  end

  # 自分が作ったグループでなければ、削除できない
  def test_deny_to_destroy_without_own_groups
    group = Group.make

    assert_raise Acl9::AccessDenied do
      delete :destroy, :id => group.id
    end
  end

  # グループメンバー管理画面の表示
  def test_member_list
    get :member_list, :id => Group.make(:user => @current_user).id

    assert_response :success
    assert_template "groups/member_list"
  end

  # グループにメンバーを追加
  def test_add_friend
    group = Group.make(:user => @current_user)
    friend = User.make
    @current_user.friend!(friend)

    assert_difference "GroupMembership.count" do
      get :add_friend, :id => group.id, :user_id => friend.id
    end

    assigns(:group)
    assert_equal friend.id, group.friends.first.id

    assert_response :redirect
    assert_redirected_to member_list_group_path(group)
  end

  # グループからメンバーを削除
  def test_remove_friend
    group = Group.make(:user => @current_user)
    friend = User.make
    @current_user.friend!(friend)
    group.friends << friend

    assert_difference "GroupMembership.count", -1 do
      get :remove_friend, :id => group.id, :user_id => friend.id
    end

    assigns(:group)
    assert_equal 0, group.friends.count

    assert_response :redirect
    assert_redirected_to member_list_group_path(group)
  end

  # 自分が作ったグループで無ければ、メンバーの一覧画面や追加や削除といった操作ができない
  def test_deny_to_manipulate_group_members
    group = Group.make

    assert_raise Acl9::AccessDenied do
      get :member_list, :id => group.id
    end

    assert_raise Acl9::AccessDenied do
      get :add_friend, :id => group.id
    end

    assert_raise Acl9::AccessDenied do
      get :remove_friend, :id => group.id
    end
  end
end

require File.dirname(__FILE__) + '/../test_helper'

# 招待管理テスト
class InvitesControllerTest < ActionController::TestCase
  def setup
    setup_emails
    @current_user = User.make
    login_as(@current_user)
    @current_user_invite = Invite.make(:user => @current_user)
    SnsConfig.master_record.update_attribute(:invite_type, SnsConfig::INVITE_TYPES[:invite])
  end

  # 登録画面の表示
  def test_new
    get :new

    assert_response :success
    assert_template 'invites/form'
    assert_kind_of Invite, assigns(:invite)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    assert_no_difference(['Invite.count']) do
      post :confirm_before_create, :invite => Invite.plan(:user_id => nil)
    end

    assert_response :success
    assert_template 'invites/confirm'
    assert_equal true, assigns(:invite).valid?
  end
  
  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    assert_no_difference(['Invite.count']) do
      post :confirm_before_create, :invite => Invite.plan(:email => "")
    end

    assert_response :success
    assert_equal false, assigns(:invite).valid?
    assert_template 'invites/form'
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    post :confirm_before_create, :invite => {}, :clear => "Clear"

    assert_response :redirect
    assert_redirected_to new_invite_path
  end
  
  # 登録データの作成
  def test_create_invite
    assert_difference(['Invite.count']) do
      post :create, :invite => Invite.plan(:body => "test", :user_id => nil)
    end

    @invite = Invite.last
    assert_equal "test", @invite.body
    assert_equal false, @emails.empty?

    assert_redirected_to complete_after_create_invite_path(@invite)
  end
  
  # 登録データの作成キャンセル
  def test_create_invite_cancel
    assert_no_difference(['Invite.count']) do
      post :create, :invite => Invite.plan, :cancel => "Cancel"
    end

    assert_not_nil assigns(:invite)
    assert_template 'invites/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_invite_fail
    assert_no_difference(['Invite.count']) do
      post :create, :invite => Invite.plan(:email => "")
    end

    assert_template 'invites/form'
  end

  # 編集画面の表示
  def test_edit
    get :edit, :id => @current_user_invite.id

    assert_response :success
    assert_template 'invites/form'
    assert_kind_of Invite, assigns(:invite)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    post(:confirm_before_update, :id => @current_user_invite.id,
        :invite => Invite.plan)

    assert_response :success
    assert_template 'invites/confirm'
    assert_equal true, assigns(:invite).valid?
  end
  
  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    post(:confirm_before_update, :id => @current_user_invite.id,
        :invite => Invite.plan(:email => ""))

    assert_response :success
    assert_template 'invites/form'
    assert_equal false, assigns(:invite).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    entry = @current_user_invite
    post(:confirm_before_update, :id => entry.id,
        :invite => Invite.plan,
        :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_invite_path(entry)
  end
  
  # 編集データの更新
  def test_update_invite
    record = @current_user_invite
    before_private_token = record.private_token

    assert_no_difference(['Invite.count']) do
      put :update, :id => record.id, :invite => Invite.plan(:body => "test")
    end

    @invite = Invite.last
    assert_equal "test", @invite.body
    assert_equal false, @emails.empty?
    assert_not_equal before_private_token, @invite.private_token

    assert_redirected_to complete_after_update_invite_path(@invite)
  end
  
  # 編集データの作成キャンセル
  def test_update_invite_cancel
    record = @current_user_invite

    put :update, :id => record.id, :invite => Invite.plan, :cancel => "Cancel"

    assert_not_nil assigns(:invite)
    assert_template 'invites/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_invite_fail
    record = @current_user_invite
    before_body = record.body

    put :update, :id => record.id, :invite => Invite.plan(:email => "", :body => "")

    assert_equal before_body, Invite.find(record.id).body

    assert_template 'invites/form'
  end

  # レコードの削除
  def test_destroy_invite
    target_id = @current_user_invite.id
    assert_difference('Invite.count', -1) do
      delete :destroy, :id => target_id
    end

    assert_redirected_to new_invite_url
  end

  # 招待状を再送付
  def test_reinvite_all
    get :reinvite_all

    assert_equal @current_user.invites.size, @emails.size
    assert_redirected_to new_invite_url
  end
end

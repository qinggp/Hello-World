require File.dirname(__FILE__) + '/../../test_helper'

class Admin::UsersControllerTest < ActionController::TestCase
  # Replace this with your real tests.

  def setup
    @current_user ||= User.make(:admin => true)
    login_as(@current_user)
    setup_emails
  end

  # 一覧画面の表示
  def test_index
    get :index

    assert_response :success
    assert_template 'admin/users/index'
    assert_not_nil assigns(:users)
  end

   # ユーザ管理一覧画面で表示件数を指定したときのページネーションの結果が正しいことを確認する
  def test_index_received_per_page
    per_page = set_per_page
    get :index, :per_page => per_page

    users = User.find(:all)
    expected_total_users = (users.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_users, assigns(:users).total_pages
    assert_equal 1, assigns(:users).current_page
    assert_equal per_page, assigns(:users).size

  end

  # ユーザ管理一覧画面でページ数をしていたときのページネーションの結果が正しいことを確認する
  def test_index_received_page
    page = set_page
    get :index, :page => page

    assert_response :success
    assert_equal page, assigns(:users).current_page
  end

  # ユーザ管理一覧画面で表示件数とページ数を指定したときの
  # ページネーションの結果が正しいことを確認する
  def test_index_received_per_page_and_page
    page, per_page = set_page, 1
    users = User.find(:all)

    get :index, :page => page, :per_page => per_page

    expected_total_users = (users.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_users, assigns(:users).total_pages
    assert_equal page, assigns(:users).current_page
    assert_equal per_page, assigns(:users).size
  end

  # 承認待ちユーザ管理画面
  def test_index_for_approval
    get :index_for_approval

    assert_response :success
    assert_template 'admin/users/index'
    assert_not_nil assigns(:users)
  end

  # ユーザ管理編集画面
  def test_edit
    user = users(:sns_tarou)
    get :edit, :id => user.id

    assert_response :success
    assert_template :"form"
  end

  # ユーザ管理編集確認画面
  def test_confirm_before_update
    post(:confirm_before_update, :id => @current_user.id,
        :user => User.plan)

    assert_response :success
    assert_template 'admin/users/confirm'
    assert_equal true, assigns(:user).valid?
  end

  # ユーザ管理変更「全てクリア」ボタン
  def test_confirm_before_update_clear
    user = users(:sns_tarou)
    updating_attributes = user
    assert_no_difference "User.count" do
      post :confirm_before_update,
           :id => user.id,
           :user => updating_attributes,
           :clear => '全てクリア'
    end
    assert_redirected_ro edit_admin_user_path(user)
  end

  # ユーザ管理変更エラー
  def test_confirm_before_update_clear
    user = users(:sns_tarou)
    updating_attributes = {
      :id => user.id,
      :name => nil
    }
    assert_no_difference "User.count" do
      post :confirm_before_update,
           :id => user.id,
           :user => updating_attributes
    end
    assert !assigns(:user).valid?
    assert_template 'admin/users/form'

  end

  # ユーザ変更完了画面
  def test_update
    assert_no_difference(['User.count']) do
      put :update, :id => @current_user.id, :user => User.plan(:name => "new")
    end

    @user = User.find(@current_user.id)
    assert_equal "new", @user.name

    assert_redirected_to complete_after_update_admin_user_path(@user)
  end

  # ユーザ管理変更「入力画面へ戻る」ボタン
  def test_update_cancel
    put :update, :id => @current_user.id, :user => User.plan, :cancel => "Cancel"

    assert_not_nil assigns(:user)
    assert_template 'admin/users/form'
  end

  # ユーザ管理パスワード編集画面
  def test_edit_passwd
    user = users(:sns_tarou)
    get :edit_passwd, :id => user.id

    assert_response :success
    assert_template 'admin/users/edit_passwd'
  end

  # ユーザ管理パスワード編集確認画面
  def test_confirm_before_update_passwd
    #パスワード入力がなかった時
    post(:confirm_before_update_passwd, :id => @current_user.id,
        :user => User.plan)

    assert_response :success
    assert_template 'admin/users/confirm_before_update_passwd'
    assert_equal true, assigns(:user).valid?

    #パスワード入力があった時
    post(:confirm_before_update_passwd, :id => @current_user.id,
    :user => User.plan(:password => 'password', :password_confirmation => 'password'))

    assert_response :success
    assert_template 'admin/users/confirm_before_update_passwd'
    assert_equal true, assigns(:user).valid?

  end

  # ユーザ管理パスワード変更「全てクリア」ボタン
  def test_confirm_before_update_passwd_clear
    user = users(:sns_tarou)
    updating_attributes = user
    assert_no_difference "User.count" do
      post :confirm_before_update_passwd,
           :id => user.id,
           :user => updating_attributes,
           :clear => '全てクリア'
    end
    assert_redirected_ro edit_passwd_admin_user_path(user)
  end

  # ユーザ管理パスワード変更エラー
  def test_confirm_before_update_passwd_clear
    user = users(:sns_tarou)
    updating_attributes = {
      :id => user.id,
      :password => 'pass',
      :password_confirmation => 'password'
    }
    assert_no_difference "User.count" do
      post :confirm_before_update_passwd,
           :id => user.id,
           :user => updating_attributes
    end
    assert !assigns(:user).valid?
    assert_template 'admin/users/edit_passwd'

  end

  # ユーザパスワード変更完了画面
  def test_update_passwd
    assert_no_difference(['User.count']) do
      put :update_passwd, :id => @current_user.id, :user => User.plan(:password => "password", :password_confirmation => "password")
    end

    @user = User.find(@current_user.id)

    #crypt('password') == "57be6b97205ae5ce95ee22e6ed71f4544cac33ae"
    assert_equal "57be6b97205ae5ce95ee22e6ed71f4544cac33ae", @user.crypted_password
    assert_redirected_to complete_after_update_admin_user_path(@user)
  end

  # ユーザ管理パスワード変更「入力画面へ戻る」ボタン
  def test_update_passwd_cancel
    put :update_passwd, :id => @current_user.id, :user => User.plan, :cancel => "Cancel"

    assert_not_nil assigns(:user)
    assert_template 'admin/users/edit_passwd'
  end

  # パラメータを何も指定しないときのユーザ検索結果の件数が全件と一致する
  def test_search_received_no_paramaters
    get :index

    assert_response :success
    assert User.count, assigns(:users).total_entries
  end

   #keywordとカテゴリを同時に指定したときの検索結果が正しいことを確認する
  def test_search_received_keyword_and_category
    set_users_for_search_user

    get :index, :keyword => '100@example.com', :search_category => 0

    assert_response :success
    assert_equal 1, assigns(:users).total_entries
    assert_equal "松江", assigns(:users).first.name

    get :index, :keyword => '朗', :search_category => 1

    assert_response :success
    assert_equal 3, assigns(:users).total_entries
    assert_equal true, assigns(:users).any?{|u| u.name == "浜田"}

    get :index, :keyword => '藤', :search_category => 1

    assert_response :success
    assert_equal 2, assigns(:users).total_entries
    assert_equal true, assigns(:users).any?{|u| u.name == "出雲"}

    get :index, :keyword => '田', :search_category => 1

    assert_response :success
    assert_equal 2, assigns(:users).total_entries
    assert_equal true, assigns(:users).any?{|u| u.name == "大田"}

    get :index, :keyword => '200', :search_category => 2

    assert_response :success
    assert_equal 1, assigns(:users).total_entries
    assert_equal "出雲", assigns(:users).first.name

    get :index, :search_category => 3

    assert_response :success
    if @current_user.invitation_id.blank?
      assert_equal 3, assigns(:users).total_entries
    else
      assert_equal 2, assigns(:users).total_entries
    end
    assert_equal true, assigns(:users).any?{|u| u.name == "浜田"}
  end

  #削除画面
  def test_delete_admin_user
    get :delete, :id => users(:sns_hanako).id

    assert_response :success
    assert_template 'admin/users/delete'
  end

  #削除確認画面
  def test_confirm_before_destroy_admin_user
    param = {:reason => '削除時メール添付メッセージ'}
    post :confirm_before_destroy, :id =>users(:sns_hanako).id, :memo =>  param

    assert_response :success
    assert_template 'admin/users/confirm_before_destroy'
    assert_equal param[:reason], assigns(:reason)
    return
  end

  # ユーザ削除「全てクリア」ボタン
  def test_confirm_before_destroy_clear
    param = {:reason => '削除時メール添付メッセージ'}
    user = users(:sns_hanako)
    assert_no_difference "User.count" do
      post :confirm_before_destroy,
           :id => user.id,
           :memo => param,
           :clear => '全てクリア'
    end
    assert_redirected_to delete_admin_user_path(user)
  end

  # ユーザ削除完了画面
  def test_destroy
    user = User.make(:face_photo_id => 1, :face_photo_type => "FacePhoto")
    FacePhoto.make(:id => 1)
    param = {:reason => '削除時メール添付メッセージ'}
    assert_difference('User.count', -1) do
      delete :destroy, :id => user.id, :memo => param
    end

    if user.face_photo_type == 'FacePhoto'
      assert_raise (ActiveRecord::RecordNotFound) do
        FacePhoto.find(user.face_photo_id)
      end
    end

    assert_equal true, RolesUser.find(:all, :conditions => {:user_id => user.id}).blank?
    assert_equal true, User.find(:all, :conditions => {:invitation_id => user.id}).blank?
    assert_equal true, User.find(:all, :conditions => {:invitation_id => user.id}).blank?

    #ユーザデータ削除確認
    assert_raise ActiveRecord::RecordNotFound do
      User.find(user.id)
    end
    assert_redirected_to complete_after_destroy_new_admin_user_path
  end

  # ユーザ削除「入力画面へ戻る」ボタン
  def test_destroy_cancel
    param = {:reason => ''}
    user = users(:sns_hanako)
    delete :destroy, :id => user.id, :cancel => "Cancel", :memo => param

    assert_template 'admin/users/delete'
  end

  # 書き込みファイル管理一覧画面の表示
  def test_wrote_administration_file
    # 顔写真ファイル管理
    get :wrote_administration_face_photo

    assert_response :success
    assert_template 'admin/users/wrote_administration_face_photo'
    assert_not_nil assigns(:users)
  end

  # ファイル書き込み管理一覧画面で表示件数を指定したときのページネーションの結果が正しいことを確認する
  def test_wrote_administartion_file_received_per_page
    set_users_for_search_photo(10)
    per_page = 5

    # 顔写真ファイル管理
    get :wrote_administration_face_photo, :per_page => per_page, :type => "file"

    users = User.find(:all, :conditions => ["face_photo_type = ?", 'FacePhoto'])
    expected_total_pages = (users.count / per_page.to_f).ceil
    assert_response :success
    assert_equal expected_total_pages, assigns(:users).total_pages
    assert_equal 1, assigns(:users).current_page
    assert_equal per_page, assigns(:users).size
  end

  # ファイル管理一覧画面でページ数をしていたときのページネーションの結果が正しいことを確認する
  def test_wrote_administration_file_received_page
    page = 2

    # 顔写真ファイル管理
    get :wrote_administration_face_photo, :page => page, :type => "file"

    assert_response :success
    assert_equal page, assigns(:users).current_page
  end

  # ファイル管理一覧画面で表示件数とページ数を指定したときの
  # ページネーションの結果が正しいことを確認する
  def test_wrote_administration_file_received_per_page_and_page
    set_users_for_search_photo(10)
    page, per_page = 2, 5

    # 顔写真ファイル管理
    users = User.find(:all, :conditions => ["face_photo_type = ?", 'FacePhoto'])
    get :wrote_administration_face_photo, :page => page, :per_page => per_page, :type => "file"
    expected_total_pages = (users.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:users).total_pages
    assert_equal page, assigns(:users).current_page
    assert_equal per_page, assigns(:users).size
  end

  # 顔写真の削除
  def test_face_photo_destroy
    face_photo = FacePhoto.make
    user = User.make(:face_photo_type => 'FacePhoto', :face_photo_id => face_photo.id)

    assert_difference 'FacePhoto.count', -1 do
      delete :face_photo_destroy, :id => user.id
    end
    user.reload
    assert_nil user.face_photo_id
    assert_nil user.face_photo_type
    assert_redirected_to wrote_administration_face_photo_admin_users_path
  end

  # 承認
  def test_approve
    SnsConfig.master_record.
      update_attribute(:approval_type,
        SnsConfig::APPROVAL_TYPES[:approved_by_administrator])
    invite_user = User.make(:approval_state => "pending", :invitation => @current_user)
    other_invter = User.make
    Invite.make(:email => invite_user.login, :user => other_invter)

    assert_difference("Message.count") do
      get :approve, :id => invite_user.id, :user => {:reason => "承認理由"}
    end

    assert_response :redirect
    assert_redirected_to edit_admin_user_path(invite_user)
    assert_equal "active", assigns(:user).approval_state
    assert_equal 3, @emails.size
    assert_match("#{invite_user.name}さんからトモダチ承認依頼がありました",
                 NKF.nkf("-mJw", @emails.last.subject))
    assert_equal 0, Invite.email_is(invite_user.login).size
  end

  # プロフィール変更依頼
  def test_rewrite_request
    user = User.make
    get :rewrite_request, :id => user.id, :user => {:reason => ""}

    assert_equal false, @emails.empty?
    assert_response :redirect
    assert_redirected_to edit_admin_user_path(user)
  end

  # 参加拒否
  def test_reject
    reject_user = User.make

    get :reject, :id => reject_user.id, :user => {:reason => ""}

    assert_equal false, @emails.empty?
    assert_response :redirect
    assert_redirected_to admin_users_path
  end

private
  # 表示件数をセットする
  def set_per_page
    5
  end

  # ユーザを設定する
  def set_page
    2
  end
  #ユーザ検索用のデータをセットする
  def set_users_for_search_user
    User.destroy_all("id != '#{@current_user.id}'")

    User.make(:id => 100, :login => '100@example.com', :first_real_name => '一朗', :last_real_name => '鈴木', :name => "松江" , :invitation_id => 100)

    User.make(:id => 200, :login => '200@example.com', :first_real_name => '二朗', :last_real_name => '佐藤', :name => "出雲", :invitation_id => 200)

    User.make(:id => 300, :login => '300@example.com', :first_real_name => '三太', :last_real_name => '田中', :name => "大田", :invitation_id => nil)

    User.make(:id => 400, :login => '400@example.com', :first_real_name => '四朗', :last_real_name => '斎藤', :name => "浜田", :invitation_id => nil)
  end

  #顔写真検索用のデータをセットする
  def set_users_for_search_photo(num)
    User.destroy_all("id != '#{@current_user.id}'")
    num.times do |count|
      User.make(:id => count, :face_photo_type => 'PreparedFacePhoto', :face_photo_id => count)
    end
    num.times do |count|
      User.make(:id => (count + 20), :face_photo_type => 'FacePhoto', :face_photo_id => (count + 20))
      FacePhoto.make(:id => (count + 20))
    end
  end

end

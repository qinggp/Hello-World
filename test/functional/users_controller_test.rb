require File.dirname(__FILE__) + '/../test_helper'
class UsersControllerTest < ActionController::TestCase

  def setup
    @current_user = User.make
    login_as(@current_user)
    setup_emails
  end

  # ユーザ登録
  def test_new
    logout
    setup_for_free_registration_test

    get :new

    assert_response :success
    assert_template "new"
  end

  # 招待登録画面
  def test_new_with_invitation
    logout
    setup_for_invitation_test

    token = Invite.make.private_token
    get :new, :private_token => token

    assert_template "new"
  end

  # 招待登録失敗（ログイン中）
  def test_new_with_invitation_fail_at_loggedin
    setup_for_invitation_test

    token = Invite.make.private_token
    get :new, :private_token => token

    assert_redirected_to failed_new_users_path
  end

  # 招待登録失敗（不正なURL）
  def test_new_with_invitation_fail_with_invalid_url
    logout
    setup_for_invitation_test

    get :new, :private_token => "invalid"

    assert_redirected_to failed_new_invalid_url_users_path
  end

  # 招待登録確認画面表示
  def test_confirm_before_create_with_invitation
    logout
    setup_for_invitation_test

    post(:confirm_before_create,
         :user => User.plan(:password => "validpass", :password_confirmation => "validpass"),
         :private_token => Invite.make.private_token)

    assert_response :success
    assert_template 'users/confirm_before_create'
    assert_equal true, assigns(:user).valid?
  end

  # ユーザ登録確認画面表示
  def test_confirm_before_create
    logout
    setup_for_free_registration_test

    post(:confirm_before_create,
         :user => User.plan(:password => "validpass", :password_confirmation => "validpass"))

    assert_response :success
    assert_template 'users/confirm_before_create'
    assert_equal true, assigns(:user).valid?
  end

  # 招待登録確認画面表示失敗
  def test_confirm_before_create_with_invitation_fail
    logout
    setup_for_invitation_test

    post(:confirm_before_create, :user => User.plan(:name => ""),
         :private_token => Invite.make.private_token)

    assert_response :success
    assert_template 'users/new'
    assert_equal false, assigns(:user).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_create_with_invitation_clear
    logout
    setup_for_invitation_test

    post(:confirm_before_create, :user => User.plan,
        :clear => "Clear", :private_token => Invite.make.private_token)

    assert_response :redirect
    assert_redirected_to new_user_path
  end

  # 招待者登録
  def test_create_user_with_invitation
    logout
    setup_for_invitation_test
    invite = Invite.make

    photo = FacePhoto.new(FacePhoto.plan)
    assert_difference(['User.count']) do
      assert_difference('Message.count', 2) do
        post :create, :private_token => invite.private_token,
        :user => User.plan(:name => "new", :password => "validpass", :password_confirmation => "validpass",
                           :photo_attributes => {:face_photo_attributes => {:image_temp => photo.image_temp}})
      end
    end

    @user = User.find_by_login(invite.email)
    assert_equal "new", @user.name
    assert_not_nil @user.face_photo.image

    # 招待状がメッセージの保存されてるか
    message = Message.receiver_id_is(@user.id).ascend_by_created_at.last
    assert_equal @user.invitation.id, message.sender_id

    # 招待者宛に、ユーザが登録したことがメッセージに保存されてるか
    message = Message.receiver_id_is(@user.invitation.id).ascend_by_created_at.last
    assert_equal @user.id, message.sender_id

    assert_equal 0, Invite.email_is(invite.email).size

    assert_redirected_to complete_after_create_user_path(@user)
  end

  # 招待者登録（他の招待者が存在する場合）
  def test_create_user_with_invitation_has_other_invitation
    logout
    setup_for_invitation_test
    invite = Invite.make
    other_invite = Invite.make(:email => invite.email)

    assert_difference('Message.count', 3) do
      assert_difference('Friendship.count', 1) do
        post :create, :private_token => invite.private_token,
        :user => User.plan(:name => "new",
                           :password => "validpass",
                           :password_confirmation => "validpass")
      end
    end

    @user = User.find_by_login(invite.email)
    friendship = Friendship.user_id_is(@user.id).first
    assert_equal other_invite.user_id, friendship.friend_id
    assert_not_nil Message.receiver_id_is(friendship.friend_id).first
    assert_equal 0, Invite.email_is(invite.email).size

    assert_redirected_to complete_after_create_user_path(@user)
  end

  # ユーザ登録
  def test_create_user
    logout
    setup_for_free_registration_test
    user_plan = User.plan(:name => "new",
                          :password => "validpass",
                          :password_confirmation => "validpass")

    assert_difference(['User.count']) do
      post(:create, :user => user_plan)
    end

    @user = User.find_by_login(user_plan[:login])
    assert_equal "new", @user.name

    assert_redirected_to complete_after_create_user_path(@user)
  end

  # 招待登録の作成キャンセル
  def test_create_user_with_invitation_cancel
    logout
    setup_for_invitation_test

    post(:create, :user => User.plan, :cancel => "Cancel",
         :private_token => Invite.make.private_token)

    assert_not_nil assigns(:user)
    assert_template 'users/new'
  end

  # 招待登録の更新の失敗（バリデーション）
  def test_create_user_with_invitation_fail
    logout
    setup_for_invitation_test

    post(:create, :user => User.plan(:name => ""),
         :private_token => Invite.make.private_token)

    assert_not_equal "", @current_user.name

    assert_template 'users/new'
  end

  # プロフィール表示
  # プロフィールがメンバーのみに公開する設定の人をログインユーザが見ようとした場合
  def test_show
    user = User.make

    get :show, :id => user.id

    assert_response :success
    assert_template "profile"
  end

  # プロフィール表示
  # プロフィールがメンバーのみに公開する設定の人を非ログインユーザが見ようとした場合
  def test_show_with_anonymous_and_profile_restraint_type_member
    logout

    user = User.make(:preference => Preference.make(:profile_restraint_type => Preference::PROFILE_RESTRAINT_TYPES[:member]))

    assert_raise Acl9::AccessDenied do
      get :show, :id => user.id
    end
  end

  # プロフィール表示
  # プロフィールが外部に公開する設定の人をログインユーザが見ようとした場合
  def test_show_with_profile_restraint_type_public
    user = User.make(:preference => Preference.make(:profile_restraint_type => Preference::PROFILE_RESTRAINT_TYPES[:public]))

    get :show, :id => user.id

    assert_response :success
    assert_template "profile"
  end

  # プロフィール表示
  # プロフィールが外部に公開する設定の人を非ログインユーザが見ようとした場合
  def test_show_with_anonymous_and_profile_restraint_type_public
    logout

    user = User.make(:preference => Preference.make(:profile_restraint_type => Preference::PROFILE_RESTRAINT_TYPES[:public]))

    get :show, :id => user.id

    assert_response :success
    assert_template "profile"
  end


  # プロフィール表示
  def test_my_home
    get :my_home

    assert_response :success
    assert_template "my_home"
  end

  # 編集画面の表示
  def test_edit
    get :edit, :id => @current_user.id

    assert_response :success
    assert_template 'users/edit'
    assert_kind_of User, assigns(:user)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    post(:confirm_before_update, :id => @current_user.id,
        :user => User.plan)

    assert_response :success
    assert_template 'users/confirm'
    assert_equal true, assigns(:user).valid?
  end

  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    post(:confirm_before_update, :id => @current_user.id,
        :user => User.plan(:first_real_name => "update"))

    assert_response :success
    assert_template 'users/edit'
    assert_equal false, assigns(:user).valid_real_name_not_changed?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    post(:confirm_before_update, :id => @current_user.id,
        :user => User.plan,
        :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_user_path(@current_user)
  end

  # 編集データの更新
  def test_update_user
    photo = FacePhoto.new(FacePhoto.plan)
    assert_no_difference(['User.count']) do
      put :update, :id => @current_user.id,
          :user => User.plan(:name => "new",
                             :photo_attributes => {:face_photo_attributes => {:image_temp => photo.image_temp}})
    end

    @user = User.find(@current_user.id)
    assert_equal "new", @user.name
    assert_not_nil @user.face_photo.image
    assert_response :redirect
    assert_redirected_to complete_after_update_user_path(@user)
  end

  # 編集データの作成キャンセル
  def test_update_user_cancel
    put :update, :id => @current_user.id, :user => User.plan, :cancel => "Cancel"

    assert_not_nil assigns(:user)
    assert_template 'users/edit'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_user_fail
    put :update, :id => @current_user.id, :user => User.plan(:name => "")

    assert_not_equal "", @current_user.name

    assert_template 'users/edit'
  end

  # 更新（デフォルト顔写真をアップロード顔写真に変更）
  def test_update_with_face_photo_before_prepared_face_photo
    @current_user.face_photo = PreparedFacePhoto.make
    @current_user.save!
    photo = FacePhoto.new(FacePhoto.plan)

    assert_no_difference(['User.count']) do
      put :update, :id => @current_user.id,
          :user => User.plan(:name => "new",
                             :photo_attributes => {
                               :face_photo_attributes => {:id => "", :image_temp => photo.image_temp},
                               :prepated_face_photo_attributes => {}})
    end

    @user = User.find(@current_user.id)
    assert_equal "new", @user.name
    assert_not_nil @user.face_photo.image
    assert_equal FacePhoto, @user.face_photo.class

    assert_redirected_to complete_after_update_user_path(@user)
  end

  # OpenID修正画面
  def test_get_edit_openid
    get :edit_openid
    assert_response :success
    assert_template "form_openid"
  end

  # OpenID修正確認画面
  def test_confirm_before_update_openid
    post :confirm_before_update_openid,
         :user => {:openid_url => "http://test.openid.net/"}

    assert_response :success
    assert_template "confirm_openid"
    assert_not_nil assigns(:user)
    assert_equal "http://test.openid.net/", assigns(:user).openid_url
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_openid_fail_clear
    post :confirm_before_update_openid,
         :clear => "Clear",
         :user => {:openid_url => "http://test.openid.net/"}

    assert_response :redirect
    assert_redirected_to edit_openid_users_path
  end

  # OpenID更新
  def test_update_openid
    assert_difference('User.count', 0) do
      put :update_openid, :user => {:openid_url => "http://test.openid.net/"}
    end

    assert_redirected_to complete_after_update_openid_users_path
    assert_equal "http://test.openid.net/", assigns(:user).openid_url
  end

  # OpenID更新キャンセル
  def test_open_id_authentication_for_update
    params = {:user => {:openid_url => "http://test.openid.net/"}}
    @dummy_result = Object.new
    stub(@dummy_result).successful?{ true }
    stub(@controller).open_id_authentication_for_update do
      @controller.send(:after_open_id_authentication_for_update,
                       @dummy_result, params[:user][:openid_url])
    end
    assert_difference('User.count', 0) do
      get :open_id_authentication_for_update, params
    end

    assert_response :redirect
  end

  # OpenID更新失敗（保存失敗）
  def test_open_id_authentication_for_update_fail
    params = {:user => {:openid_url => "http://test.openid.net/"}}
    @dummy_result = Object.new
    stub(@dummy_result).successful?{ false }
    stub(@dummy_result).message{ "fail" }
    stub(@controller).open_id_authentication_for_update do
      @controller.send(:after_open_id_authentication_for_update, @dummy_result, "http://test.openid.net/")
    end
    assert_difference('User.count', 0) do
      get :open_id_authentication_for_update, params
    end

    assert_template "form_openid"
    assert_equal "fail", flash[:error]
  end

  # ID、パスワード修正
  def test_edit_id_password
    get :edit_id_password

    assert_template "form_id_password"
  end

  # 編集データ確認画面表示
  def test_confirm_before_update_id_password
    post(:confirm_before_update_id_password,
         :id => @current_user.id,
         :user => User.plan(:current_password => "monkey",
                            :password => "validpass",
                            :password_confirmation => "validpass"))

    assert_response :success
    assert_template 'users/confirm'
    assert_equal true, assigns(:user).valid_for_edit_id_password?
    assert_equal "validpass", assigns(:user).password
  end

  # 編集データ確認画面表示失敗
  def test_confirm_before_update_id_password_fail
    exist_login = User.make.login
    post(:confirm_before_update_id_password, :id => @current_user.id,
        :user => User.plan(:login => exist_login,
                           :current_password => "invalid",
                           :password => "a",
                           :password_confirmation => "b"))

    assert_response :success
    assert_template 'users/form_id_password'
    errors = assigns(:user).errors
    assert_not_nil errors[:login]
    assert_not_nil errors[:current_password]
    assert_not_nil errors[:password]
    assert_equal false, assigns(:user).valid_for_edit_id_password?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_id_password_clear
    post(:confirm_before_update_id_password, :id => @current_user.id,
         :user => User.plan(:current_password => "monkey"),
         :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_id_password_users_path
  end

  # ID、パスワード更新
  def test_update_id_password
    assert_difference('User.count', 0) do
      put(:update_id_password,
          :user => User.plan(:login => "update@update.com",
                             :current_password => "monkey",
                             :password => "update",
                             :password_confirmation => "update"))
    end

    user = assigns(:user)
    assert_redirected_to complete_after_update_id_password_user_path(user)
    assert_equal "update@update.com", user.login
    assert  user.authenticated?("update")
  end

  # ID、パスワード更新キャンセル
  def test_update_id_password_cancel
    assert_difference('User.count', 0) do
      put(:update_id_password,
          :user => User.plan(:login => "update@update.com",
                             :current_password => "monkey",
                             :password => "update",
                             :password_confirmation => "update"),
          :cancel => "Cancel")
    end

    assert_template "form_id_password"
  end

  # ID、パスワード変更完了画面表示
  def test_complete_after_update_id_password
    assert_not_nil @request.session[:user_id]

    get :complete_after_update_id_password

    assert_nil @request.session[:user_id]
  end

  # 顔写真表示
  def test_show_face_photo
    photo = FacePhoto.make

    get :show_face_photo,
        :image_id => photo.id,
        :image_class => photo.class.to_s

    assert_response :success
  end

  # 顔写真表示
  def test_show_face_photo_invalid
    photo = FacePhoto.make

    assert_raise Mars::AccessDenied do
      get :show_face_photo,
          :image_id => photo.id,
          :image_class => "Invalid"
    end

    assert_response :success
  end

  # 名前変更依頼画面
  def test_get_edit_request_new_name
    get :edit_request_new_name
    assert_response :success
    assert_template "form_request_new_name"
  end

  # 名前変更依頼確認画面
  def test_confirm_before_request_new_name
    post :confirm_before_request_new_name,
         :user => {:change_first_real_name => "太郎", :change_last_real_name => "SNS"}

    assert_response :success
    assert_template "confirm_request_new_name"
  end

  # 入力情報クリア（名前変更依頼確認時）
  def test_confirm_before_request_new_name_clear
    post :confirm_before_request_new_name,
         :clear => "Clear",
         :user => {:change_first_real_name => "太郎", :change_last_real_name => "SNS"}

    assert_response :redirect
    assert_redirected_to edit_request_new_name_users_path
  end

  # 名前変更依頼確認画面表示失敗
  def test_confirm_before_request_new_name_fail
    post :confirm_before_request_new_name,
         :user => {:change_first_real_name => "太郎", :change_last_real_name => ""}

    assert_template "form_request_new_name"
  end

  # 名前変更依頼
  def test_request_new_name
    assert_difference('User.count', 0) do
      post :request_new_name,
          :user => {:change_first_real_name => "太郎", :change_last_real_name => "SNS"}
    end

    assert !@emails.empty?
    assert_redirected_to complete_after_request_new_name_users_path
  end

  # 名前変更キャンセル
  def test_request_new_name_cancel
    assert_difference('User.count', 0) do
      post :request_new_name,
           :cancel => "Cancel",
           :user => {:change_first_real_name => "太郎", :change_last_real_name => "SNS"}
    end

    assert_equal 0, @emails.size
    assert_template "form_request_new_name"
  end

  # ニックネーム重複チェック
  def test_nickname_unique_check
    user = User.make(:name => @current_user.name)

    xhr :get, :nickname_unique_check, :name => user.name

    assert_response :success
  end

  # ニックネーム重複チェック（匿名ユーザからのアクセス）
  def test_nickname_unique_check_by_anonymous
    logout
    user = User.make(:name => "unique")

    xhr :get, :nickname_unique_check, :name => user.name

    assert_response :success
  end

  # 郵便番号検索
  def test_search_zipcode
    zipcode = JpAddress.make.zipcode

    get :search_zipcode, :zipcode => zipcode

    assert_equal 1, assigns(:jp_addressess).size
    assert_template "search_zipcode"
  end

  # メンバー検索
  def test_search_member
    u = User.make
    u.hobbies << Hobby.make

    post :search_member, :user => {:search_hobby_id => u.hobbies.first.id, :name => u.name}

    res = assigns(:users)
    assert_equal false, res.empty?
    assert_equal true, res.any?{|r| r.name == u.name}
  end

  # 退会情報編集
  def test_edit_for_leave
    get :edit_for_leave

    assert_template "form_for_leave"
  end

  # 名前変更依頼確認画面
  def test_confirm_before_leave
    post :confirm_before_leave,
         :user => {:current_password => "monkey", :leave_reason => "テスト"}

    assert_response :success
    assert_template "confirm_for_leave"
  end

  # 入力情報クリア（名前変更依頼確認時）
  def test_confirm_before_leave_clear
    post :confirm_before_leave,
         :clear => "Clear",
         :user => {:current_password => "monkey", :leave_reason => "テスト"}

    assert_response :redirect
    assert_redirected_to edit_for_leave_users_path
  end

  # 名前変更依頼確認画面表示失敗
  def test_confirm_before_leave_fail
    post :confirm_before_leave,
         :user => {:current_password => "", :leave_reason => ""}

    user = assigns(:user)
    assert_template "form_for_leave"
    assert_not_nil user.errors[:current_password]
    assert_not_nil user.errors[:leave_reason]
  end

  # 退会
  def test_leave
    delete(:leave,
           :user => {:current_password => "monkey", :leave_reason => "testtest"})

    assert_redirected_to complete_after_leave_users_path
    assert_nil User.find_by_id(@current_user.id)
  end

  # 退会キャンセル
  def test_leave_cancel
    delete(:leave,
           :cancel => "Cancel",
           :user => {:current_password => "monkey", :leave_reason => "testtest"})

    assert_template "form_for_leave"
    assert_not_nil User.find_by_id(@current_user.id)
  end

  # 退会キャンセル
  def test_leave_fail
    delete(:leave,
           :user => {:current_password => "invalid", :leave_reason => "testtest"})

    assert_template "form_for_leave"
    assert_not_nil User.find_by_id(@current_user.id)
    user = assigns(:user)
    assert_not_nil user.errors[:current_password]
  end

  # 退会後確認画面
  def test_complete_after_leave
    get :complete_after_leave

    assert_template "share/complete"
  end

  # 携帯メールアドレス修正
  def test_edit_mobile_email
    get :edit_mobile_email

    assert_template "form_mobile_email"
  end

  # 編集データ確認画面表示
  def test_confirm_before_update_mobile_email
    post(:confirm_before_update_mobile_email,
         :id => @current_user.id,
         :user => User.plan(:current_password => "monkey"))

    assert_response :success
    assert_template 'users/confirm_mobile_email'
    assert_equal true, assigns(:user).valid_for_mobile_email?
  end

  # 編集データ確認画面表示失敗
  def test_confirm_before_update_mobile_email_fail
    exist_login = User.make.login
    post(:confirm_before_update_mobile_email, :id => @current_user.id,
        :user => User.plan(:current_password => ""))

    assert_response :success
    assert_template 'users/form_mobile_email'
    errors = assigns(:user).errors
    assert_not_nil errors[:current_password]
    assert_equal false, assigns(:user).valid_for_mobile_email?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_mobile_email_clear
    post(:confirm_before_update_mobile_email, :id => @current_user.id,
         :user => User.plan(:current_password => "monkey"),
         :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_mobile_email_users_path
  end

  # 携帯メールアドレス更新
  def test_update_mobile_email
    assert_difference('User.count', 0) do
      put(:update_mobile_email,
          :user => User.plan(:current_password => "monkey",
                             :mobile_email => "update@example.com"))
    end

    user = assigns(:user)
    assert_redirected_to complete_after_update_mobile_email_user_path(user)
    assert_equal "update@example.com", user.mobile_email
  end

  # 携帯メールアドレス更新キャンセル
  def test_update_mobile_email_cancel
    assert_difference('User.count', 0) do
      put(:update_mobile_email,
          :user => User.plan(:current_password => "monkey",
                             :mobile_email => "update@example.com"),
          :cancel => "Cancel")
    end

    assert_template "form_mobile_email"
  end

  # 携帯メールアドレス変更完了画面表示
  def test_complete_after_update_mobile_email
    get :complete_after_update_mobile_email

    assert_template "share/complete"
  end

  # トモダチ紹介文編集画面の表示
  def test_edit_friend_description
    get :edit_friend_description, :id => User.make

    assert_response :success
    assert_template "users/profile"
  end

  # トモダチ紹介文の更新
  def test_update_friend_description
    friend = User.make
    @current_user.friend!(friend)

    assert_difference("Message.count") do
      put :update_friend_description, :id => friend.id,
          :friendship => {:description => "description",
                          :relation => 2,
                          :contact_frequency => 3}
    end

    friendship = assigns(:friendship)
    assert_equal "description", friendship.description
    assert_equal 2, friendship.relation
    assert_equal 3, friendship.contact_frequency

    message = Message.sender_id_is(@current_user.id).receiver_id_is(friend.id).first
    assert message
    assert_equal "新着紹介文のお知らせ", message.subject

    email = @emails.first
    assert_equal [friend.login], email.to
    assert_equal [friend.login], email.reply_to
    assert_equal "【#{SnsConfig.title}】新着紹介文のお知らせ", NKF.nkf("-mJw", email.subject)
    assert_match /紹介文を掲載しました。/, email.body

    assert_response :redirect
    assert_redirected_to user_path(friend)
  end

  # トモダチ紹介文更新失敗
  def test_edit_friend_description_fail
    friend = User.make
    friendship = Friendship.make(:user => @current_user,
                                 :friend => friend)

    put :update_friend_description, :id => friend.id,
        :friendship => Friendship.plan(:description => "",
                                       :relation => 2,
                                       :contact_frequency => 3)

    friendship = assigns(:friendship).reload
    assert_equal Friendship.plan[:description], friendship.description
    assert_equal Friendship.plan[:relation], friendship.relation
    assert_equal Friendship.plan[:contact_frequency], friendship.contact_frequency

    assert_response :success
    assert_template "users/profile"
  end

  # トモダチ紹介文の消去
  def test_clear_friend_description
    friend = User.make
    friendship = Friendship.make(:user => @current_user,
                                 :friend => friend,
                                 :description => "description",
                                 :relation => 2,
                                 :contact_frequency => 3)

    put :clear_friend_description, :id => friend.id

    friendship = assigns(:friendship)
    assert_nil friendship.description
    assert_equal Friendship::RELATIONS[:nothing], friendship.relation
    assert_equal Friendship::CONTACT_FREQUENCIES[:nothing], friendship.contact_frequency

    assert_response :redirect
    assert_redirected_to user_path(friend)
  end

  # 未承認のユーザのアクセス
  def test_deactive_user_access
    SnsConfig.master_record.
      update_attribute(:approval_type,
        SnsConfig::APPROVAL_TYPES[:approved_by_administrator])
    pending_user = User.make(:approval_state => "pending")
    login_as(pending_user)

    get :show

    assert_redirected_to failed_deactive_users_path
  end

  # トモダチ申請作成
  def test_new_friend_application
    display_user = User.make

    get :new_friend_application, :id => display_user.id

    assert_response :success
    assert_template "users/profile"
  end

  # トモダチ申請作成（携帯）
  def test_new_friend_application_mobile
    set_mobile_user_agent
    display_user = User.make

    get :new_friend_application, :id => display_user.id

    assert_response :success
    assert_template "form_friend_application"
  end

  # トモダチ申請作成確認画面（携帯）
  def test_confirm_before_create_friend_application_mobile
    set_mobile_user_agent
    display_user = User.make

    post(:confirm_before_create_friend_application, :id => display_user.id,
         :friendship => {:message => "お願いします",
           :relation => Friendship::RELATIONS[:peer],
           :contact_frequency => Friendship::CONTACT_FREQUENCIES[:many]
         })

    assert_response :success
    assert_template "confirm_friend_application"
    assert_equal Friendship::RELATIONS[:peer], assigns(:friendship).relation
  end

  # トモダチ申請作成確認画面（携帯）
  def test_confirm_before_create_friend_application_clear_mobile
    set_mobile_user_agent
    display_user = User.make

    post(:confirm_before_create_friend_application,
         :id => display_user.id,
         :friendship => {},
         :clear => "clear")

    assert_response :redirect
    assert_redirected_to new_friend_application_user_path(display_user)
  end

  # トモダチ申請
  def test_create_friend_application
    display_user = User.make

    assert_difference('Friendship.count') do
      assert_difference('Message.count') do
        post(:create_friend_application,
             :id => display_user.id,
             :friendship => {:message => "お願いします",
               :relation => Friendship::RELATIONS[:peer],
               :contact_frequency => Friendship::CONTACT_FREQUENCIES[:many],
             })
      end
    end

    assert_equal 1, @emails.size
    assert_match("#{@current_user.name}さんからトモダチ承認依頼がありました",
                 NKF.nkf("-mJw", @emails.first.subject))
    assert_response :redirect
    assert_redirected_to user_path(display_user)

    friendship = Friendship.last
    assert_equal @current_user.id, friendship.user.id
    assert_equal display_user.id, friendship.friend.id
    assert_equal false, friendship.approved
  end

  # トモダチ申請キャンセル（携帯）
  def test_create_friend_application_cancel_mobile
    set_mobile_user_agent
    display_user = User.make

    post(:create_friend_application,
         :id => display_user.id,
         :friendship => {},
         :cancel => "Cancel")

    assert_response :success
    assert_template "form_friend_application"
  end

  # トモダチ再申請
  def test_recreate_friend_application
    display_user = User.make
    friendship = Friendship.make(:user => @current_user, :friend => display_user, :approved => false)

    assert_difference('Friendship.count', 0) do
      assert_difference('Message.count') do
        post :recreate_friend_application, :id => display_user.id
      end
    end

    assert_equal 1, @emails.size
    assert_match("#{@current_user.name}さんからトモダチ承認依頼がありました",
                 NKF.nkf("-mJw", @emails.first.subject))
    assert_response :redirect
    assert_redirected_to user_path(display_user)
  end

  # トモダチ申請承認（携帯）
  def test_new_approve_friend_mobile
    set_mobile_user_agent
    display_user = User.make
    friendship = Friendship.make(:user => display_user, :friend => @current_user, :approved => false)

    get :new_approve_friend, :id => display_user.id

    assert_response :success
    assert_template "form_approve_friend_mobile"
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:friendship)
  end

  # トモダチ申請承認（携帯）
  def test_confirm_before_approve_friend_mobile
    set_mobile_user_agent
    display_user = User.make
    friendship = Friendship.make(:user => display_user, :friend => @current_user, :approved => false)

    post(:confirm_before_approve_friend,
         :id => display_user.id,
         :friendship => {
           :relation => Friendship::RELATIONS[:peer],
           :contact_frequency => Friendship::CONTACT_FREQUENCIES[:many],
         })

    assert_response :success
    assert_template "confirm_approve_friend"
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:friendship)
    assert_equal Friendship::RELATIONS[:peer], assigns(:friendship).relation
  end

  # トモダチ申請承認クリア（携帯）
  def test_confirm_before_approve_friend_clear_mobile
    set_mobile_user_agent
    display_user = User.make
    friendship = Friendship.make(:user => display_user, :friend => @current_user, :approved => false)

    post(:confirm_before_approve_friend,
         :id => display_user.id,
         :clear => "クリア")

    assert_response :redirect
    assert_redirected_to new_approve_friend_user_path(display_user)
  end

  # トモダチ追加
  def test_approve_friend
    display_user = User.make
    friendship = Friendship.make(:user => display_user, :friend => @current_user, :approved => false)

    assert_difference('Friendship.count') do
      assert_difference('Message.count') do
        post(:approve_friend,
             :id => display_user.id,
             :friendship => {:message => "お願いします",
               :relation => Friendship::RELATIONS[:peer],
               :contact_frequency => Friendship::CONTACT_FREQUENCIES[:many],
             })
      end
    end

    assert_equal 1, @emails.size
    assert_match("#{@current_user.name}さんがあなたのトモダチ依頼を承認しました",
                 NKF.nkf("-mJw", @emails.first.subject))
    assert_response :redirect
    assert_redirected_to user_path(display_user)

    friendship = Friendship.find(friendship.id)
    assert_equal display_user.id, friendship.user.id
    assert_equal @current_user.id, friendship.friend.id
    assert_equal true, friendship.approved
    assert_equal true, @current_user.friend_user?(display_user)
  end

  # トモダチ申請承認キャンセル（携帯）
  def test_approve_friend_cancel_mobile
    set_mobile_user_agent
    display_user = User.make
    friendship = Friendship.make(:user => display_user, :friend => @current_user, :approved => false)

    post(:approve_friend,
         :id => display_user.id,
         :cancel => "キャンセル")

    assert_response :success
    assert_template "form_approve_friend"
  end

  # トモダチ申請拒否
  def test_reject_friend_application
    display_user = User.make
    Friendship.make(:user => @current_user, :friend => display_user, :approved => false)

    assert_difference('Friendship.count', -1) do
      post(:reject_friend_application, :id => display_user.id)
    end

    assert_response :redirect
    assert_redirected_to user_path(display_user)
  end

  # 簡単ログイン設定画面
  def test_edit_mobile_ident_mobile
    set_mobile_user_agent

    get :edit_mobile_ident

    assert_response :success
    assert_template "form_mobile_ident_mobile"
  end

  # 簡単ログイン設定
  def test_set_mobile_ident
    set_mobile_user_agent_docomo
    @request.env['HTTP_X_DCMGUID'] = "12345678901234567890"

    put :set_mobile_ident

    assert_response :redirect
    assert_redirected_to complete_after_mobile_ident_users_path
    assert_equal "12345678901234567890", assigns(:user).mobile_ident
  end

  # 簡単ログイン設定解除
  def test_release_mobile_ident
    set_mobile_user_agent

    put :release_mobile_ident

    assert_response :redirect
    assert_nil assigns(:user).mobile_ident
    assert_redirected_to complete_after_mobile_ident_users_path
  end

  private

  # ユーザ登録方法が招待制テスト時のsetup
  def setup_for_invitation_test
    SnsConfig.master_record.
      update_attribute(:entry_type, SnsConfig::ENTRY_TYPES[:invitation])
  end

  # ユーザ登録方法が自由登録時のsetup
  def setup_for_free_registration_test
    SnsConfig.master_record.
      update_attribute(:entry_type, SnsConfig::ENTRY_TYPES[:free_registration])
  end
end

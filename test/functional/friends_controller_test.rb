require File.dirname(__FILE__) + '/../test_helper'

class FriendsControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
    setup_emails
  end

  # トモダチ一覧画面表示テスト
  def test_index
    get :index

    assert_response :success
    assert_template "friends/index"
  end

  # グループ表示時
  def test_index_for_group
    group = Group.make(:user => @current_user)

    get :index, :group_id => group.id

    assert_response :success
    assert_template "friends/index"
    assert_not_nil assigns(:group)
  end

  # 指定したユーザのトモダチ一覧画面表示テスト
  def test_index_for_user
    display_user = User.make
    friend = User.make
    display_user.friend!(friend)

    get :index, :user_id => display_user.id

    assert_response :success
    assert_template "friends/index"
    assert_equal 1, assigns(:friends).size
  end

  # 招待トモダチ一覧画面表示テスト
  def test_index_for_invite
    invite_friend = User.make(:invitation_id => @current_user.id)
    @current_user.friend!(invite_friend)

    get :index_for_invite, :user_id => @current_user.id

    assert_response :success
    assert_template "friends/index_for_invite"
    assert_equal 1, assigns(:friends).size
  end

  # トモダチ管理画面表示テスト
  def test_maintenance
    friend_number = 3
    friends = Array.new(friend_number){ User.make }
    friends.each{|friend| @current_user.friend!(friend) }

    get :maintenance

    assert_equal friend_number, assigns(:friends).total_entries

    assert_response :success
    assert_template "friends/maintenance"
  end

  # 紹介文一覧表示テスト
  def test_list_description
    friend_number = 3
    friends = Array.new(friend_number){ User.make }

    # @current_userに対して、紹介文を作成する
    friends.each do |f|
      f.friend! @current_user
      fs = f.friendship_by_user_id(@current_user.id)
      fs.update_attributes(:description => "description")
    end

    get :list_description, :user_id => @current_user.id

    friendships = assigns(:friendships)
    assert_equal friend_number, friendships.total_entries

    assert_response :success
    assert_template "friends/list_description"
  end

  # トモダチ依頼中一覧
  def test_list_request
    friend = User.make
    Friendship.make(:user => @current_user, :friend => friend, :approved => false)

    get :list_request

    assert_not_nil assigns(:user)
    assert_equal 1, assigns(:friendships).size
    assert_template "list_request"
  end

  # トモダチ関係を破棄するテスト
  def test_break_off
    friend = User.make
    Friendship.make(:user => @current_user, :friend => friend,
                    :approved => false, :created_at => 2.day.ago)
    @current_user.friend!(friend)

    assert_difference "Friendship.count", -2 do
      delete :break_off, :id => friend.id
    end
    
    assert !friend.friend_user?(@current_user)
    assert !@current_user.friend_user?(friend)
  end

  # トモダチ関係を破棄できない(トモダチになったばかりの場合)
  def test_break_off_fail_with_hot
    friend = User.make
    @current_user.friend!(friend)

    assert_difference "Friendship.count", 0 do
      delete :break_off, :id => friend.id
    end

    assert_redirected_to maintenance_friends_path
  end

  # トモダチ関係を破棄できない(招待者の場合)
  def test_break_off_fail_with_invitation
    friend = User.make(:invitation => @current_user)
    @current_user.friend!(friend)

    assert_difference "Friendship.count", 0 do
      delete :break_off, :id => friend.id
    end

    assert_redirected_to maintenance_friends_path
  end

  # 非ログイン状態ではアクセス拒否される
  def test_access_deny_without_login
    logout

    assert_raise Acl9::AccessDenied do
      get :index
    end
  end

  # トモダチ紹介メッセージ作成画面
  def test_new_message
    friend = User.make(:invitation => @current_user)
    @current_user.friend!(friend)

    get :new_message, :user_id => friend.id

    assert_template "message_form"
  end

  # トモダチ紹介メッセージ作成確認画面
  def test_confirm_before_create_message
    friend = User.make(:invitation => @current_user)
    other_friend = User.make(:invitation => @current_user)
    @current_user.friend!(friend)
    @current_user.friend!(other_friend)

    post(:confirm_before_create_message, :user_id => friend.id,
         :message => Message.plan, :receiver_ids => ["#{other_friend.id}"])

    assert_template "message_confirm"
  end


  # トモダチ紹介メッセージ作成
  def test_create_message
    friend = User.make(:invitation => @current_user)
    other_friend = User.make(:invitation => @current_user)
    @current_user.friend!(friend)
    @current_user.friend!(other_friend)

    assert_difference("Message.count") do
      post(:create_message, :user_id => friend.id,
           :message => Message.plan, :receiver_ids => ["#{other_friend.id}"])
    end

    assert_equal 1, @emails.size
    assert_redirected_to complete_after_create_message_user_friends_path(friend)
  end
end

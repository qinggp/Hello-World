require File.dirname(__FILE__) + '/../test_helper'

# お問い合わせ管理テスト
class AsksControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
    setup_emails
  end

  # お問い合わせ画面の表示
  def test_new
    get :new

    assert_response :success
    assert_template 'asks/form'
    assert_equal @current_user.login, assigns(:user).login
  end

  # お問い合わせ画面の表示（非ログインユーザ）
  def test_new_with_anonymous
    logout

    get :new

    assert_response :success
    assert_template 'asks/form'
    assert_nil assigns(:user).login
  end

  # お問い合わせ確認画面表示
  def test_confirm_before_create
    post :confirm_before_create,
    :user => {
      :first_real_name => @current_user.first_real_name,
      :last_real_name => @current_user.last_real_name,
      :login => @current_user.login,
      :ask_body => "問い合わせ",
      :error_repeatability => User::ERROR_REPEATABILITIES[:yes]
    }

    assert_response :success
    assert_template 'asks/confirm'
    assert_equal true, assigns(:user).valid_for_ask?
    assert_not_nil assigns(:user).ask_body
    assert_not_nil assigns(:user).error_repeatability
  end
  
  # お問い合わせ確認画面表示失敗
  def test_confirm_before_create_fail
    post :confirm_before_create, :user => {}

    assert_response :success
    assert_template 'asks/form'
    assert_equal false, assigns(:user).valid_for_ask?
  end

  # 入力情報クリア
  def test_confirm_before_create_clear
    post :confirm_before_create, :user => {}, :clear => "Clear"

    assert_response :redirect
    assert_redirected_to new_ask_path
  end
  
  # お問い合わせ
  def test_create_ask
    post :create,
    :user => {
      :first_real_name => @current_user.first_real_name,
      :last_real_name => @current_user.last_real_name,
      :login => @current_user.login,
      :ask_body => "問い合わせ"
    }

    assert_equal 2, @emails.size
    assert_equal @current_user.id, assigns(:user).id
    assert_redirected_to complete_after_create_asks_path
  end

  # お問い合わせ（非ログイン時）
  def test_create_ask_with_anonymous
    logout
    user = User.make_unsaved

    post :create,
    :user => {
      :first_real_name => user.first_real_name,
      :last_real_name => user.last_real_name,
      :login => user.login,
      :ask_body => "問い合わせ"
    }

    assert_equal 2, @emails.size
    assert_nil assigns(:user).id
    assert_redirected_to complete_after_create_asks_path
  end
  
  # お問い合わせキャンセル
  def test_create_ask_cancel
    post :create, :user => {}, :cancel => "Cancel"

    assert_not_nil assigns(:user)
    assert_template 'asks/form'
  end

  # お問い合わせ失敗（バリデーション）
  def test_create_ask_fail
    post :create, :user => {}

    assert_template 'asks/form'
  end
end

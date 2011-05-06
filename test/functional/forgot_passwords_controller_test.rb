require File.dirname(__FILE__) + '/../test_helper'
class ForgotPasswordsControllerTest < ActionController::TestCase
  def setup
    setup_emails
  end

  # パスワード再発行画面表示
  def test_new
    get :new

    assert_template "new"
  end

  # パスワード再発行URL作成
  def test_create
    user = User.make

    post :create, :forgot_password => {:email => user.login}

    assert !@emails.empty?
    assert_template "create"
  end

  # パスワード再発行URL作成失敗
  def test_create_fail
    user = User.make

    post :create, :forgot_password => {:email => "fail@test.com"}

    assert_template "new"
  end

  # パスワード再設定画面表示
  def test_reset
    user = User.make
    pas = ForgotPassword.make(:email => user.login, :user => user)

    get :reset, :reset_code => pas.reset_code

    assert_template "reset"
    assert_not_nil assigns(:user)
  end

  # パスワード再設定画面表示失敗
  def test_reset_fail
    user = User.make
    pas = ForgotPassword.make_unsaved(:email => user.login, :user => user,
                                      :expiration_date => Date.today.last_year)
    # NOTE:expiration_dateを勝手に入れるので無効化
    stub(pas).before_create{}
    pas.save!

    get :reset, :reset_code => pas.reset_code

    assert_redirected_to new_forgot_password_path
    assert_nil assigns(:user)
  end

  # パスワード再設定
  def test_update_after_forgetting
    user = User.make
    before_pass = user.crypted_password
    pas = ForgotPassword.make(:email => user.login, :user => user)

    post :update_after_forgetting, :reset_code => pas.reset_code,
         :user => {:password => "newnewnew", :password_confirmation => "newnewnew" }

    user = assigns(:user)
    assert_not_equal before_pass, user.crypted_password
    assert_redirected_to login_path
  end

  # パスワード再設定失敗
  def test_update_after_forgetting_fail
    user = User.make
    before_pass = user.crypted_password
    pas = ForgotPassword.make(:email => user.login, :user => user)

    post :update_after_forgetting,
         :reset_code => pas.reset_code, :user => {:password => "new" }

    user = assigns(:user)
    assert_equal before_pass, user.crypted_password
    assert_template "reset"
  end

  # パスワード再設定失敗
  def test_update_after_forgetting_fail_with_empty_password
    user = User.make
    before_pass = user.crypted_password
    pas = ForgotPassword.make(:email => user.login, :user => user)

    post :update_after_forgetting,
         :reset_code => pas.reset_code, :user => {:password => "", :password_confirmation => "" }

    user = assigns(:user)
    assert_equal before_pass, user.crypted_password
    assert_template "reset"
  end
end

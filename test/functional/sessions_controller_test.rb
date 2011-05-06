require File.dirname(__FILE__) + '/../test_helper'
require 'sessions_controller'

# Re-raise errors caught by the controller.
class SessionsController; def rescue_action(e) raise e end; end

class SessionsControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :users

  def test_should_login_and_redirect
    post :create, :login => 'quentin@example.com', :password => 'monkey'
    assert session[:user_id]
    assert_response :redirect
  end

  def test_should_fail_login_and_not_redirect
    post :create, :login => 'quentin@example.com', :password => 'bad password'
    assert_nil session[:user_id]
    assert_response :redirect
  end

  def test_should_logout
    login_as :quentin
    get :destroy
    assert_nil session[:user_id]
    assert_response :redirect
  end

  def test_should_remember_me
    @request.cookies["auth_token"] = nil
    post :create, :login => 'quentin@example.com', :password => 'monkey', :remember_me => "1"
    assert_not_nil @response.cookies["auth_token"]
  end

  def test_should_not_remember_me
    @request.cookies["auth_token"] = nil
    post :create, :login => 'quentin@example.com', :password => 'monkey', :remember_me => "0"
    assert @response.cookies["auth_token"].blank?
  end

  def test_should_delete_token_on_logout
    login_as :quentin
    get :destroy
    assert @response.cookies["auth_token"].blank?
  end

  def test_should_login_with_cookie
    users(:quentin).remember_me
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    assert @controller.send(:logged_in?)
  end

  def test_should_fail_expired_cookie_login
    users(:quentin).remember_me
    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    assert !@controller.send(:logged_in?)
  end

  def test_should_fail_cookie_login
    users(:quentin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :new
    assert !@controller.send(:logged_in?)
  end

  # OpenID認証
  def test_open_id_authentication
    current_user = User.make
    params = {:openid_url => current_user.openid_url}
    @dummy_result = Object.new
    stub(@dummy_result).successful?{ true }
    stub(@controller).open_id_authentication do
      @controller.send(:after_open_id_authentication,
                       @dummy_result, params[:openid_url])
    end
    put :create, params

    assert_response :redirect
    assert_redirected_to my_home_users_path
  end

  # OpenID認証失敗
  def test_open_id_authentication_fail
    current_user = User.make
    params = {:openid_url => current_user.openid_url}
    @dummy_result = Object.new
    stub(@dummy_result).successful?{ false }
    stub(@dummy_result).message{ "fail" }
    stub(@controller).open_id_authentication do
      @controller.send(:after_open_id_authentication,
                       @dummy_result, params[:openid_url])
    end
    put :create, params

    assert_equal "fail", flash[:notice]
    assert_response :redirect
    assert_redirected_to failed_login_sessions_path
  end


  # 携帯端末番号ログイン機能テスト
  def test_create_with_mobile_ident
    set_mobile_user_agent_docomo
    @request.env['HTTP_X_DCMGUID'] = "12345678901234567890"
    @request.env['REMOTE_ADDR'] = "210.153.84.0/24"

    user = User.make(:mobile_ident => "12345678901234567890")

    post :create_with_mobile_ident

    assert_not_nil assigns(:current_user)
    assert_nil flash[:error]
    assert_redirected_to my_home_users_path
  end

  # 携帯端末番号ログイン機能テスト(識別番号不一致）
  def test_create_with_mobile_ident_fail
    set_mobile_user_agent_docomo
    @request.env['HTTP_X_DCMGUID'] = "12345678901234567890"
    @request.env['REMOTE_ADDR'] = "210.153.84.0/24"

    user = User.make(:mobile_ident => "fail")

    post :create_with_mobile_ident

    assert_nil assigns(:current_user)
    assert_redirected_to login_path
    assert_equal "個体識別番号が一致しません。", flash[:error]
  end

  # 携帯端末番号ログイン機能テスト(個体識別番号取得不可）
  def test_create_with_mobile_ident_fail_pc
    set_mobile_user_agent_docomo
    user = User.make(:mobile_ident => "fail")

    post :create_with_mobile_ident

    assert_equal false, assigns(:current_user)
    assert_redirected_to login_path
    assert_equal "個体識別番号が取得できません。", flash[:error]
  end

  # 携帯ログイン時の端末情報保存
  def test_login_with_mobile_ident_save
    set_mobile_user_agent_docomo
    @request.env['HTTP_X_DCMGUID'] = "12345678901234567890"

    post :create, :login => 'quentin@example.com', :password => 'monkey'
    assert session[:user_id]
    assert_response :redirect
    assert_equal "12345678901234567890", session[:mobile_ident]
  end

  protected
    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end

    def cookie_for(user)
      auth_token users(user).remember_token
    end
end

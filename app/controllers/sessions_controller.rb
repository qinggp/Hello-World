# -*- coding: utf-8 -*-
# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  skip_before_filter :deactive_check

  def new
    @title_off = true unless request.mobile?
    return redirect_to my_home_users_path if current_user
    if SnsConfig.login_display_type || request.mobile?
      @show_main_search = true
      render "login_portal"
    else
      render "login_form"
    end
  end

  def create
    @title_off = true
    logout_keeping_session!
    if using_open_id?
      open_id_authentication
    else
      password_authentication
    end
  end

  # 携帯端末番号ログイン機能（簡単ログイン機能）
  def create_with_mobile_ident
    @title_off = true
    logout_keeping_session!
    case
    when !request.mobile? || !request.mobile.ident
      failed_login("個体識別番号が取得できません。")
    when @current_user = User.find_by_mobile_ident(request.mobile.ident)
      successful_login(@current_user)
    else
      failed_login("個体識別番号が一致しません。")
    end
  end

  def destroy
    logout_killing_session!
    redirect_back_or_default('/')
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    new_session_path
  end

  protected

  # OpenIDによる認証
  def open_id_authentication
    authenticate_with_open_id do |result, openid_url|
      after_open_id_authentication(result, openid_url)
    end
  end

  # ログイン名、パスワードによる認証
  def password_authentication
    user = User.authenticate(params[:login], params[:password])
    if user
      successful_login(user)
    else
      failed_login("ログインに失敗しました '#{params[:login]}'")
    end
  end

  private

  # OpenID認証後処理
  def after_open_id_authentication(result, openid_url)
    if result.successful?
      if @current_user = User.find_by_openid_url(openid_url)
        successful_login(@current_user)
      else
        failed_login("入力されたOpenIDをもつユーザがいません(#{openid_url})")
      end
    else
      failed_login(result.message)
    end
  end

  # ログイン成功時
  def successful_login(user)
    self.current_user = user
    new_cookie_flag = (params[:remember_me] == "1")
    handle_remember_cookie! new_cookie_flag
    user.update_logged_in_at!
    redirect_to my_home_users_path
  end

  # ログイン失敗時
  def failed_login(message)
    if request.mobile?
      flash[:error] = message
      redirect_to login_path
    else
      flash[:notice] = message
      redirect_to failed_login_sessions_path
    end
  end
end

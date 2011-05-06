class ForgotPasswordsController < ApplicationController

  # パスワード再発行画面
  def new
    @forgot_password = ForgotPassword.new
  end

  # パスワード再発行URL作成
  def create
    @forgot_password = ForgotPassword.new(params[:forgot_password])
    @forgot_password.user = User.find_by_login(@forgot_password.email)
    @forgot_password.user ||= User.find_by_mobile_email(@forgot_password.email)

    if @forgot_password.save
      ForgotPasswordMailer.deliver_forgot_password(@forgot_password)
      render "create"
    else
      if @forgot_password.errors.on(:user)
        @forgot_password.errors.clear
        flash[:error] = "このメールアドレス(ログインユーザー)での登録はありません。再度メールアドレスをご確認ください。"
      end
      render :action => "new"
    end
  end

  # パスワード再設定画面
  def reset
    begin
      @user = ForgotPassword.find(:first, :conditions => ['reset_code = ? and expiration_date > ?', params[:reset_code], Time.now]).user
    rescue
      flash[:error] = 'パスワード再設定のURLが不正、もしくは失効しています。再度、パスワード再発行を行ってください。'
      redirect_to(new_forgot_password_path)
    end
  end

  # パスワード再設定
  def update_after_forgetting
    @forgot_password = ForgotPassword.find_by_reset_code(params[:reset_code])
    @user = @forgot_password.user unless @forgot_password.nil?

    if !params[:user][:password].blank? &&
        !params[:user][:password_confirmation].blank? &&
        @user.update_attributes(params[:user])
      @forgot_password.destroy
      ForgotPasswordMailer.deliver_reset_password(@user)
      redirect_to login_path
    else
      flash[:error] = '入力したパスワードが不正です。'
      render :action => :reset, :reset_code => params[:reset_code]
    end
  end

  def contents_home_path
    forgot_password_path
  end
end

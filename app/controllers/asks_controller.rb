# お問い合わせ管理
class AsksController < ApplicationController

  with_options :redirect_to => :asks_url do |con|
    con.verify :params => "user", :only => %w(confirm_before_create create)
    con.verify :method => :post, :only => %w(confirm_before_create create)
  end

  # お問い合わせフォームの表示
  def new
    if logged_in?
      @user = User.new(:first_real_name => current_user.first_real_name,
                       :last_real_name => current_user.last_real_name,
                       :login => current_user.login)
    else
      @user = User.new
    end
    render "form"
  end

  # お問い合わせ確認画面表示
  def confirm_before_create
    @user = User.new(params[:user])
    return redirect_to new_ask_path if params[:clear]

    if @user.valid_for_ask?
      render "confirm"
    else
      render "form"
    end
  end

  # お問い合わせ
  def create
    if logged_in?
      @user = User.find(current_user.id)
      @user.attributes = params[:user]
    else
      @user = User.new(params[:user])
    end
    return render "form" if params[:cancel] || !@user.valid_for_ask?

    AskNotifier.deliver_notification(@user)
    AskNotifier.deliver_notification_to_admin(@user, request)
    
    redirect_to complete_after_create_asks_path
  end

  # レコード作成完了画面表示
  def complete_after_create
    @message = "お問い合わせありがとうございました。\n後ほど担当者から返答させていただきます。 "
    render "/share/complete", :layout => "application"
  end
end

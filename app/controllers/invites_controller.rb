# 招待管理
class InvitesController < ApplicationController
  before_filter :verify_invite_type
  before_filter :set_current_user_invites
  before_filter :set_invites

  with_options :redirect_to => :new_invite_url do |con|
    con.verify :params => "id", :only => %w(show destroy confirm_before_update)
    con.verify :params => "invite", 
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  access_control do
    allow logged_in
  end

  # 登録フォームの表示．
  def new
    @invite = Invite.new
    render "form"
  end

  # 編集フォームの表示．
  def edit
    @invite = @current_user_invites.find(params[:id])
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @invite = Invite.new(params[:invite])
    @invite.user = current_user
    return redirect_to new_invite_path if params[:clear]

    if @invite.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @invite = @current_user_invites.find(params[:id])
    @invite.attributes = params[:invite]
    return redirect_to edit_invite_path(@invite) if params[:clear]

    if @invite.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 登録データをDBに保存．
  def create
    @invite = Invite.new(params[:invite])
    @invite.user = current_user
    return render "form" if params[:cancel] || !@invite.valid?

    Invite.transaction do
      @invite.save!
    end

    InviteNotifier.deliver_notification(@invite)
    redirect_to complete_after_create_invite_path(@invite)
  end

  # 更新データをDBに保存．
  def update
    @invite = @current_user_invites.find(params[:id])
    @invite.attributes = params[:invite]
    return render "form" if params[:cancel] || !@invite.valid?

    Invite.transaction do
      @invite.save!
    end

    InviteNotifier.deliver_notification(@invite)
    redirect_to complete_after_update_invite_path(@invite)
  end

  # レコードの削除
  def destroy
    @invite = @current_user_invites.find(params[:id])
    @invite.destroy

    redirect_to new_invite_url
  end

  def complete_after_create
    @message = "招待状の送付完了いたしました。\n\n<font color='red'>※招待状が迷惑メール判定される場合がありますので、\n念のため連絡もしてみましょう！</font>"
    render "/share/complete", :layout => "application"
  end
  alias_method :complete_after_update, :complete_after_create

  # 招待状を再送付
  def reinvite_all
    @current_user_invites.each do |invite|
      invite.mail_sender_me = true
      InviteNotifier.deliver_notification(invite)
    end
    redirect_to new_invite_path
  end

  private
  # 一覧の表示と並び替え，レコードの検索．
  def set_invites
    @invites = @current_user_invites.find(:all,
      :order => params[:order] ? construct_sort_order : Invite.default_index_order)
  end

  def set_current_user_invites
    @current_user_invites = current_user.invites
  end

  # 招待機能が「有り」になっているか確認
  def verify_invite_type
    if SnsConfig.master_record.invite_type_no_invite?
      redirect_to root_url
      return false
    end
  end
end

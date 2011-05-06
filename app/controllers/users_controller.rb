# ユーザ管理
#
# SNSユーザ情報の表示、作成、削除、編集を行う
class UsersController < ApplicationController
  include Mars::UnpublicImageAccessible

  unpublic_image_accessible :model_name => "face_photo"
  before_filter :set_invite_by_private_token,
    :only => %w(new confirm_before_create create),
    :if => Proc.new{ SnsConfig.master_record.entry_type_invitation? }
  skip_before_filter :deactive_check,
    :only => %w(edit confirm_before_update
                update complete_after_update
                failed_deactive failed_deactive_by_pause)

  with_options :redirect_to => :root_url do |con|
    con.verify :params => "id", :only => %w(edit destroy confirm_before_update update)
    con.verify :params => "user",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update update_friend_description clear_friend_description)
    con.verify :method => :delete, :only => %w(destroy)
  end

  access_control do
    public_actions = %w(show show_face_photo complete_after_leave
                        complete_after_update_id_password new
                        confirm_before_create create failed_new_invalid_url
                        failed_new complete_after_create search_index news_index
                        failed_new_invitation_only nickname_unique_check
                        prepared_face_photo_choices search_zipcode)
    owner_actions = %w(edit confirm_before_update update destroy)
    allow all, :to => public_actions
    allow logged_in, :except => (public_actions + owner_actions)
    allow logged_in, :to => owner_actions, :if => :user_owner?
    deny anonymous, :to => %w(show), :unless => :anoymous_viewable?
  end

  # ユーザの情報を表示
  def show
    render_profile
  end

  # マイホーム画面
  def my_home
    @title = "マイホーム"
    @show_main_search = true
    @user = current_user
  end

  # ユーザ登録画面表示
  def new
    @user = @invite.nil? ? User.new : User.new(:login => @invite.email)
    render_new
  end

  # ユーザ登録確認画面
  def confirm_before_create
    @user = User.new(user_new_form_attributes)
    return redirect_to new_user_path if params[:clear]

    if @user.valid?
      self.unpublic_image_uploader_key = @user.face_photo.try(:image_temp)
      render "confirm_before_create"
    else
      render_new
    end
  end

  # ユーザ登録
  def create
    @user = User.new(user_new_form_attributes)
    return render_new if params[:cancel] || !@user.valid?

    ActiveRecord::Base.transaction do
      @user.save!
      # 承認フローが無く、かつ招待制である場合
      if SnsConfig.master_record.approval_type_no_approval? && SnsConfig.master_record.entry_type_invitation?
        cleanup_invites!
      end
    end

    clear_unpublic_image_uploader_key
    redirect_to complete_after_create_user_path(@user)
  end

  # 編集フォームの表示．
  def edit
    @user = current_user
    render_edit
  end

  # 編集確認画面表示
  def confirm_before_update
    @user = current_user
    @user.attributes = params[:user]
    return redirect_to edit_user_path(@user) if params[:clear]

    if @user.valid? && @user.valid_real_name_not_changed?
      self.unpublic_image_uploader_key = @user.face_photo.try(:image_temp)
      render "confirm"
    else
      render_edit
    end
  end

  # 更新データをDBに保存．
  def update
    @user = current_user
    @user.attributes = params[:user]
    return render_edit if params[:cancel] || !(@user.valid? && @user.valid_real_name_not_changed?)

    ActiveRecord::Base.transaction do
      UsersHobby.delete_all(['user_id = ?', @user.id])
      @user.save!
    end

    clear_unpublic_image_uploader_key
    redirect_to complete_after_update_user_path(@user)
  end

  # OpenID修正画面表示
  def edit_openid
    @user = current_user
    render "form_openid"
  end

  # OpenID修正確認画面表示
  def confirm_before_update_openid
    @user = current_user
    @user.openid_url = params[:user][:openid_url]
    return redirect_to edit_openid_users_path if params[:clear]
    return render "form_openid" unless @user.valid?
    render "confirm_openid"
  end

  # OpenID認証（修正用）
  def open_id_authentication_for_update
    authenticate_with_open_id do |result, openid_url|
      after_open_id_authentication_for_update(result, openid_url)
    end
  end

  # OpenID修正
  def update_openid
    @user = current_user
    @user.openid_url = params[:user][:openid_url]
    return render "form_openid" if params[:cancel] || !@user.valid?

    ActiveRecord::Base.transaction do
      @user.save!
    end

    redirect_to complete_after_update_openid_users_path
  end

  # OpenID修正完了
  def complete_after_update_openid
    @message = "OpenID情報を登録・変更しました。"
    @back_link_template = "complete_update_openid_back_link"
    render "/share/complete", :layout => "application"
  end

  # ID、パスワード修正画面表示
  def edit_id_password
    @user = current_user
    render "form_id_password"
  end

  # ID、パスワード修正確認画面表示
  def confirm_before_update_id_password
    @user = current_user
    @user.attributes = params[:user]
    return redirect_to edit_id_password_users_path if params[:clear]
    return render "form_id_password" unless @user.valid_for_edit_id_password?
    render "confirm_id_password"
  end

  # ID、パスワード修正確認画面表示
  def update_id_password
    @user = current_user
    @user.attributes = params[:user]
    if params[:cancel] || !@user.valid_for_edit_id_password?
      return render "form_id_password"
    end

    ActiveRecord::Base.transaction do
      @user.save!
    end

    redirect_to complete_after_update_id_password_user_path(@user)
  end

  # ID、パスワード修正完了
  def complete_after_update_id_password
    @message = "認証情報変更が完了いたしました。"
    @back_link_template = "complete_update_id_password_back_link"
    logout_keeping_session!
    render "/share/complete", :layout => "application"
  end

  # 携帯メールアドレス修正画面表示
  def edit_mobile_email
    @user = current_user
    render "form_mobile_email"
  end

  # 携帯メールアドレス修正確認画面表示
  def confirm_before_update_mobile_email
    @user = current_user
    @user.attributes = params[:user]
    return redirect_to edit_mobile_email_users_path if params[:clear]
    return render "form_mobile_email" unless @user.valid_for_mobile_email?
    render "confirm_mobile_email"
  end

  # 携帯メールアドレス修正確認画面表示
  def update_mobile_email
    @user = current_user
    @user.attributes = params[:user]
    if params[:cancel] || !@user.valid_for_mobile_email?
      return render "form_mobile_email"
    end

    ActiveRecord::Base.transaction do
      @user.save!
    end

    redirect_to complete_after_update_mobile_email_user_path(@user)
  end

  # 携帯メールアドレス修正完了
  def complete_after_update_mobile_email
    @message = "携帯メールアドレス登録修正完了いたしました"
    @back_link_template = "complete_update_mobile_email_back_link"
    render "/share/complete", :layout => "application"
  end

  # メンバー検索
  def search_member
    search_opts = User.search_member_options(params[:user])
    if search_opts.empty?
      @users = User.by_activate.paginate(:all, paginate_options)
    else
      @users = search_opts.keys.inject(User) do |res, opt|
        res.send(opt, search_opts[opt])
      end.by_activate.paginate(paginate_options)
    end
  end

  # 顔写真表示
  def show_face_photo
    unless User.face_photo_class?(params[:image_class])
      raise Mars::AccessDenied, "params[:image_class] invalid."
    end
    face_photo = params[:image_class].constantize.find(params[:image_id])
    if face_photo.image =~ Mars::IMAGE_EXT_REGEX
      x_send_file(face_photo.image(params[:image_type]),
                :type => "image/jpeg",
                :disposition => "inline",
                :filename => "イメージ表示")
    else
      x_send_file(face_photo.image(params[:image_type]))
    end
  end

  # デフォルト顔写真表示
  def prepared_face_photo_choices
    render "prepared_face_photo_choices", :layout => "popup"
  end

  # 名前変更依頼編集画面表示
  def edit_request_new_name
    @user = current_user
    render "form_request_new_name"
  end

  # 名前変更依頼確認画面
  def confirm_before_request_new_name
    @user = current_user
    @user.attributes = params[:user]
    return redirect_to edit_request_new_name_users_path if params[:clear]
    return render "form_request_new_name" unless @user.valid_for_request_new_name?
    render "confirm_request_new_name"
  end

  # 名前変更依頼確認画面
  def request_new_name
    @user = current_user
    @user.attributes = params[:user]
    if params[:cancel] || !@user.valid_for_request_new_name?
      return render "form_request_new_name"
    end

    RequestNewNameNotifier.deliver_notification(@user,request)
    redirect_to complete_after_request_new_name_users_path
  end

  # 名前変更依頼完了画面
  def complete_after_request_new_name
    @message = "変更依頼ありがとうございました。\n後ほど管理者にて変更いたします。 "
    @back_link_template = "complete_request_new_name_back_link"
    render "/share/complete", :layout => "application"
  end

  # ニックネーム重複チェック
  def nickname_unique_check
    scope = current_user.nil? ? User : User.by_other_user(current_user)
    size = scope.name_is(params[:name]).count
    render :update do |page|
      case
      when params[:name].blank?
        page.alert('ニックネームを入力してください')
      when size > 0
        page.alert("すでに#{size}名の方がこのニックネームを使用しています。\n重複登録は可能ですが、既存の方たちとの兼ね合いも考えてみましょう。")
      else
        page.alert('このニックネームでの登録はありませんでした。')
      end
    end
  end

  # 郵便番号検索
  def search_zipcode
    @jp_addressess = JpAddress.search_by_zipcode(params[:zipcode])
    render "search_zipcode", :layout => "popup"
  end

  # 退会情報編集
  def edit_for_leave
    @user = current_user
    render "form_for_leave"
  end

  # 退会情報確認
  def confirm_before_leave
    @user = current_user
    @user.attributes = params[:user]
    return redirect_to edit_for_leave_users_path if params[:clear]
    return render "form_for_leave" unless @user.valid_for_leave?
    render "confirm_for_leave"
  end

  # 退会
  def leave
    @user = current_user
    @user.attributes = params[:user]
    if params[:cancel] || !@user.valid_for_leave?
      return render "form_for_leave"
    end

    dup_user = @user.dup
    ActiveRecord::Base.transaction do
      @user.destroy
    end

    LeaveSnsNotifier.deliver_notification_to_admin(dup_user)
    LeaveSnsNotifier.deliver_notification_to_leave_user(dup_user)
    redirect_to complete_after_leave_users_path
  end

  # 退会完了画面
  def complete_after_leave
    @message = "退会手続きが完了いたしました。\nまたのご利用をお待ちしております。"
    @back_link_template = "complete_leave_back_link"
    render "/share/complete", :layout => "application"
  end

  # トモダチ紹介文の編集画面
  def edit_friend_description
    @profile_header_partial = "form_friend_description"
    @friendship = current_user.friendship_by_user_id(params[:id])
    if request.mobile?
      return render "edit_friend_description"
    else
      render_profile
    end
  end

  # トモダチ紹介文の編集確認画面（携帯用）
  def confirm_before_update_friend_description
    @friendship = current_user.friendship_by_user_id(params[:id])
    @friendship.attributes = params[:friendship]

    return redirect_to edit_friend_description_user_path(params[:id]) if params[:clear]

    if  !@friendship.valid_for_edit_description?
      return render "edit_friend_description"
    end
  end

  # トモダチ紹介文の更新
  def update_friend_description
    @friendship = current_user.friendship_by_user_id(params[:id])
    @friendship.attributes = params[:friendship]

    if params[:cancel] || !@friendship.valid_for_edit_description?
      if request.mobile?
        return render "edit_friend_description"
      else
        @profile_header_partial = "form_friend_description"
        return render_profile
      end
    end

    ActiveRecord::Base.transaction do
      @friendship.save!
      @user = @friendship.friend
      Mars::Messageable.
        send_row_message!(:receiver => @user, :sender => current_user,
                          :body => render_to_string(:partial => "/users/mail/newer_friend_description"),
                          :subject => "新着紹介文のお知らせ")
    end

    if request.mobile?
      redirect_to complete_after_update_friend_description_user_path(params[:id])
    else
      redirect_to user_path(params[:id])
    end
  end

  # トモダチ紹介文の更新完了画面（携帯用）
  def complete_after_update_friend_description
    @message = "紹介文登録完了しました。"
    @back_link_template = "profile_back_link"
    render "/share/complete", :layout => "application"
  end

  # トモダチ紹介文消去確認画面（携帯用）
  def confirm_before_clear_friend_description
    render "confirm_before_clear_friend_description"
  end

  # トモダチ紹介文を消去する
  def clear_friend_description
    @friendship = current_user.friendship_by_user_id(params[:id])

    ActiveRecord::Base.transaction do
      @friendship.clear_description!
    end

    if request.mobile?
      redirect_to complete_after_clear_friend_description_user_path(params[:id])
    else
      redirect_to user_path(params[:id])
    end

  end

  # トモダチ紹介文削除完了画面（携帯用）
  def complete_after_clear_friend_description
    @message = "紹介文削除完了しました。"
    @back_link_template = "profile_back_link"
    render "/share/complete", :layout => "application"
  end

  # トモダチ申請作成画面（携帯のみ）
  def new_friend_application
    @profile_header_partial = "form_friend_application"
    @user = User.find(params[:id])
    @friendship = Friendship.new
    return render "form_friend_application" if request.mobile?
    render_profile
  end

  # トモダチ申請作成確認画面（携帯のみ）
  def confirm_before_create_friend_application
    @user = User.find(params[:id])
    @friendship = Friendship.new(params[:friendship].merge(:user => current_user, :friend => @user))
    if @friendship.valid?
      return redirect_to new_friend_application_user_path(@user) if params[:clear]
      render "confirm_friend_application"
    else
      return render "form_friend_application" if request.mobile?
    end
  end

  # トモダチ申請
  def create_friend_application
    @user = User.find(params[:id])
    @friendship = Friendship.new(params[:friendship].merge(:user => current_user, :friend => @user))

    if request.mobile? && params[:cancel]
      return render "form_friend_application"
    end

    if @friendship.valid?
      friend_apply!(@friendship)
    else
      flash[:error] = "既に#{@user.name}さんとトモダチか、トモダチ依頼を申し込んでいます。"
    end

    redirect_to user_path(@user)
  end

  # トモダチ申請再依頼
  def recreate_friend_application
    @user = User.find(params[:id])
    @friendship = current_user.friendship_by_user_id(@user.id)

    Message.transaction do
      Mars::Messageable.
        send_row_message!(:receiver => @user, :sender => current_user,
                          :body => render_to_string(:partial => "/users/mail/friend_application"),
                          :subject => "#{current_user.name}さんからトモダチ承認依頼がありました")
    end

    redirect_to user_path(@user)
  end

  # トモダチ申請承認画面（携帯用）
  def new_approve_friend
    @user = User.find(params[:id])
    @friendship = @user.friendship_by_user_id(current_user.id)
    render "form_approve_friend"
  end

  # トモダチ申請承認確認画面（携帯用）
  def confirm_before_approve_friend
    @user = User.find(params[:id])
    @friendship = @user.friendship_by_user_id(current_user.id)
    @friendship.attributes = params[:friendship]
    return redirect_to new_approve_friend_user_path(@user) if params[:clear]
    render "confirm_approve_friend"
  end

  # トモダチ追加
  def approve_friend
    @user = User.find(params[:id])
    @friendship = @user.friendship_by_user_id(current_user.id)
    @friendship.attributes = params[:friendship]

    if request.mobile? && params[:cancel]
      return render "form_approve_friend"
    end

    ActiveRecord::Base.transaction do
      @friendship.save!
      current_user.friend!(@user)
      Mars::Messageable.
        send_row_message!(:receiver => @user, :sender => current_user,
                          :body => render_to_string(:partial => "/users/mail/approve_friend"),
                          :subject => "#{current_user.name}さんがあなたのトモダチ依頼を承認しました")
    end

    redirect_to user_path(@user)
  end

  # トモダチ申請拒否
  def reject_friend_application
    @user = User.find(params[:id])

    ActiveRecord::Base.transaction do
      current_user.break_off!(@user)
    end

    redirect_to user_path(@user)
  end

  # 簡単ログイン設定画面
  def edit_mobile_ident
    @user = current_user
    render "form_mobile_ident"
  end

  # 簡単ログイン設定
  def set_mobile_ident
    @user = current_user
    @user.update_attribute(:mobile_ident, request.mobile.try(:ident))
    redirect_to complete_after_mobile_ident_users_path
  end

  # 簡単ログイン設定解除
  def release_mobile_ident
    @user = current_user
    @user.update_attribute(:mobile_ident, nil)
    redirect_to complete_after_mobile_ident_users_path
  end

  # 簡単ログイン設定終了
  def complete_after_mobile_ident
    @user = current_user
    @message = "簡単ログイン設定を更新しました。"
    @back_link_template = "complete_mobile_ident_back_link"
    render "/share/complete", :layout => "application"
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    my_home_users_path
  end

  # ユーザ登録が招待制の際に招待されていないユーザが登録しようとした時
  # のエラー画面表示
  def failed_new_invitation_only
    @title = SnsConfig.title + "は招待制です"
  end

  private

  # OpenID認証後の処理
  def after_open_id_authentication_for_update(result, openid_url)
    if result.successful?
      redirect_to update_openid_users_path(:user => {:openid_url => openid_url})
    else
      flash.now[:error] = result.message
      @user = current_user
      render "form_openid"
    end
  end

  # ユーザの所有者か？
  def user_owner?
    params[:id].to_i == current_user.id
  end

  # 登録画面表示
  def render_new
    @user.face_photo = nil
    return render "new"
  end

  # 編集画面表示
  def render_edit
    @user.face_photo = User.find(params[:id]).face_photo
    return render "edit"
  end

  # 一覧表示オプション
  def paginate_options
    @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : User.default_index_order),
      :per_page => (params[:per_page] ? per_page_for_all(User) : 10)
    }
    return @paginate_options
  end

  # プロフィール画面を表示する際に必要な処理を行う
  def render_profile
    @user = User.find(params[:id])
    @title = @user.name + "さんのプロフィール"

    render "profile"
  end

  # 招待情報を設定
  def set_invite_by_private_token
    if logged_in?
      redirect_to failed_new_users_path
      return false
    end
    unless params.has_key?(:private_token)
      redirect_to failed_new_invitation_only_users_path
      return false
    end
    @invite = Invite.find_by_private_token(params[:private_token])
    unless @invite
      redirect_to failed_new_invalid_url_users_path
      return false
    end
  end

  # ユーザ登録時のフォームパラメータ
  def user_new_form_attributes
    if SnsConfig.master_record.entry_type_invitation?
      return params[:user].merge(:login => @invite.email,
                                 :invitation => @invite.user)
    else
      return params[:user]
    end
  end

  # トモダチ申請
  def friend_apply!(friendship, send_email = true)
    ActiveRecord::Base.transaction do
      friendship.save!
      attr = {:receiver => friendship.friend, :sender => friendship.user,
        :body => render_to_string(:partial => "/users/mail/friend_application",
                                  :locals => {:friendship => friendship}),
        :subject => "#{friendship.user.name}さんからトモダチ承認依頼がありました"}
      if send_email
        Mars::Messageable.send_row_message!(attr)
      else
        Message.new(Message.default_attributes(attr, attr[:sender])).save!
      end
    end
  end

  # 招待情報の後始末
  def cleanup_invites!
    # 招待状をメッセージに保存
    Message.new(
      Message.default_attributes(
       {:receiver => @user, :sender => @user.invitation,
        :body => render_to_string(:partial => "/invite_notifier/friend_notificaion"),
        :subject => "#{@user.invitation.full_real_name}さんから #{SnsConfig.title} への招待状が届いています"},
      @user.invitation)
    ).save!

    # 招待者に、ユーザが登録したことをメッセージに保存
    Message.new(
      Message.default_attributes(
       {:receiver => @user.invitation, :sender => @user,
        :body => render_to_string(:partial => "/users/mail/notify_invitation_of_user_entried"),
        :subject => "#{@user.name}さんがユーザ登録を行いました"},
       @user)
    ).save!

    # 他の招待者にトモダチ依頼
    Invite.email_is(@user.login).user_id_does_not_equal(@user.invitation.id).each do |invite|
      friendship = Friendship.new(:user => @user, :friend => invite.user)
      friend_apply!(friendship, false)
    end

    # 招待状削除
    Invite.destroy_all(:email => @user.login)
  end

  # 非ログインユーザがプロフィールページを見れるかどうか
  def anoymous_viewable?
    user = User.find(params[:id])
    user.profile_displayable?(current_user)
  end
end

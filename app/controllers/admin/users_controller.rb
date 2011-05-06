# ユーザ管理（管理側）
class Admin::UsersController < Admin::ApplicationController

  include Mars::UnpublicImageAccessible
  unpublic_image_accessible :model_name => :face_photo

  with_options :redirect_to => :admin_users_url do |con|
    con.verify :params => "id", :only => %w(face_photo_destroy destroy confirm_before_update delete edit_passwd update_passwd confirm_before_destroy confirm_before_update_passwd)
    con.verify :params => "user",
      :only => %w(confirm_before_update_passwd update_passwd confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_update confirm_before_update_passwd comfirm_before_destroy)
    con.verify :method => :put, :only => %w(update update_passwd)
    con.verify :method => :delete, :only => %w(destroy face_photo_destroy)
  end

  # 書き込み管理プロフィール画像
  def wrote_administration_face_photo
    if params[:per_page] && params[:per_page].to_i == 0
      @paginated = false
    else
      @paginated = true
    end

    conditions = ['face_photo_id is not null and face_photo_type = ?', "FacePhoto"]
    if params[:search_id] &&  params[:search_id] != ''
       @search_id =  params[:search_id]
       conditions[0] += " and id = ?"
       conditions << @search_id
    end
    if @paginated
      @users = User.paginate(
        :conditions => conditions,
        :per_page => (params[:per_page] ? params[:per_page] : 10),
        :page => params[:page] )
    else
      @users = User.find(:all, :conditions => conditions)
    end
  end

  # プロフィール画像の削除
  def face_photo_destroy
    user = User.find(params[:id])
    face_photo = FacePhoto.find(user.face_photo_id)
    
    if user.update_attribute(:face_photo_id, nil) && user.update_attribute(:face_photo_type, nil)
      face_photo.destroy
    else
      flash[:error] = "削除失敗しました。"
    end
    redirect_to wrote_administration_face_photo_admin_users_path

  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    @users = users_for_index
    render "index"
  end

  # 承認待ちユーザ一覧の表示と並び替え，レコードの検索．
  def index_for_approval
    @users = users_for_index(["approval_state != ?"], ['active'])
    render "index"
  end

  # 編集フォームの表示．
  def edit
    @user ||= User.find(params[:id])
    render "form"
  end

  # 編集確認画面表示
  def confirm_before_update
    @user = User.find(params[:id])
    @user.attributes = params[:user]

    return redirect_to edit_admin_user_path(@user.id) if params[:clear]

    if @user.valid?
      self.unpublic_image_uploader_key = @user.face_photo.try(:image_temp)
      render "confirm"
    else
      render "form"
    end
  end

  # 更新データをDBに保存．
  def update
    @user = User.find(params[:id])
    @user.attributes = params[:user]
    return render "form" if params[:cancel] || !@user.valid?

    User.transaction do
      @user.save!
    end

    redirect_to complete_after_update_admin_user_path(@user)
  end

  #パスワード編集フォームの表示
  def edit_passwd
    @user ||= User.find(params[:id])
  end

  #パスワード編集確認画面表示
  def confirm_before_update_passwd
    @user = User.find(params[:id])
    @user.attributes = params[:user]

    return redirect_to edit_passwd_admin_user_path(@user) if params[:clear]

    if @user.valid?
      render "confirm_before_update_passwd"
    else
      render "edit_passwd"
    end
  end

  #パスワード更新データをDBに保存
  def update_passwd
    @user = User.find(params[:id])
    @user.attributes = params[:user]
    return render 'edit_passwd' if params[:cancel] || !@user.valid?

    User.transaction do
      @user.save!
    end

    redirect_to complete_after_update_admin_user_path(@user)
  end

  #削除フォームの表示
  def delete
    @user ||= User.find(params[:id])
  end

  # 削除確認画面表示
  def confirm_before_destroy
    @user = User.find(params[:id])
    @reason = params[:memo][:reason]

    return redirect_to delete_admin_user_path(@user) if params[:clear]

    render "confirm_before_destroy"

  end

  # レコードの削除
  def destroy
    @user = User.find(params[:id])
    @reason = params[:memo][:reason]
    return render "delete" if params[:cancel]

    User.transaction do
      @user.destroy
    end
    
    #サイト管理者にメール送信
    UserMailer.deliver_destroy_admin_user(@user,@reason)

    redirect_to complete_after_destroy_new_admin_user_path
  end

  # ボタン名によってリダイレクトアクションを選別
  def dispatch_for_approval
    %w(approve rewrite_request reject).each do |action_name|
      if params[action_name]
        redirect_to send("#{action_name}_admin_user_path",
                         {:id => params[:id],
                           :user => params[:user]})
        break
      end
    end
  end

  # 承認
  def approve
    @user = User.find(params[:id])
    @user.reason = params[:user][:reason]

    ActiveRecord::Base.transaction do
      @user.activate_with_notification!(current_user)
      other_invites = Invite.email_is(@user.login).user_id_does_not_equal(current_user.id)
      other_invites.each do |other_invite|
        @friendship = Friendship.new(:user => @user, :friend => other_invite.user)
        @friendship.save!
        Mars::Messageable.
          send_row_message!(:receiver => other_invite.user, :sender => @user,
                            :body => render_to_string(:partial => "/users/mail/friend_application"),
                            :subject => "#{@user.name}さんからトモダチ承認依頼がありました")
      end
      Invite.delete_all(["email = ?", @user.login])
    end

    redirect_to edit_admin_user_path(@user)
  end

  # プロフィール変更依頼
  def rewrite_request
    @user = User.find(params[:id])
    @user.reason = params[:user][:reason]
    UserApprovalNotifier.deliver_rewrite_request(@user)
    redirect_to edit_admin_user_path(@user)
  end

  # レコードの削除
  def reject
    @user = User.find(params[:id])
    @user.reason = params[:user][:reason]

    User.transaction do
      @user.destroy
    end

    # サイト管理者にメール送信
    UserApprovalNotifier.deliver_reject(@user)

    redirect_to admin_users_path
  end

  private

  #一覧画面用ユーザリスト生成
  def users_for_index(sqls=[], values=[])
    if params[:per_page] && params[:per_page].to_i == 0
      @paginated = false
    else
      @paginated = true
    end

    unless params[:search_category].blank?
      case params[:search_category].to_i
      #e-mail
      when 0
        unless params[:keyword].blank?
          sqls << "login = ?"
          values << params[:keyword]
        end
      #name
      when 1
        unless params[:keyword].blank?
          sqls << "last_real_name LIKE ? OR first_real_name LIKE ? OR name LIKE ?"
          values += ["%#{params[:keyword]}%", "%#{params[:keyword]}%", "%#{params[:keyword]}%"]
        end
      #id
      when 2
        unless params[:keyword].blank?
          sqls << "id = ?"
          values << params[:keyword].to_i
        end
      #no_invited
      when 3
        sqls << "invitation_id is NULL"
      end
    end


    order = construct_sort_order
    condition = [sqls.map{|sql| "(#{sql})"}.join(" AND "), values].flatten

    if @paginated
      return User.paginate(:per_page => params[:per_page] ? params[:per_page] : 20,
                           :page => params[:page],
                           :conditions => condition,
                           :order => order)
    else
      return User.find(:all, :conditions => condition, :order => order)
    end
  end
end

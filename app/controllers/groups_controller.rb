# トモダチをグループとしてわけて管理するためのコントローラ
class GroupsController < ApplicationController
  include Mars::Messageable
  include Mars::UnpublicImageAccessible

  unpublic_image_accessible :model_name => :message_attachment

  with_options :redirect_to => :groups_url do |con|
    con.verify :params => "id", :only => %w(show destroy confirm_before_update confirm_before_destroy)
    con.verify :params => "group",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  access_control do
    allow logged_in
    deny all, :unless => :group_owner?,
              :to => %w(edit confirm_before_update update complete_after_update
                         destroy member_list add_friend remove_friend)
  end

  before_filter :load_group,
                :only => %w(new_message confirm_before_create_message
                            create_message complete_after_create_message)

  # 一覧の表示と並び替え，レコードの検索．
  def index
    @groups = Group.paginate(:all, paginate_options)
  end

  # レコードの詳細情報の表示．
  def show
    @group = current_user.groups.find(params[:id])
  end

  # 登録フォームの表示．
  def new
    @group ||= Group.new

    render_form
  end

  # 編集フォームの表示．
  def edit
    @group ||= current_user.groups.find(params[:id])
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @group = Group.new(params[:group].merge(:user => current_user))
    return redirect_to new_group_path if params[:clear]

    if @group.valid?
      render "confirm"
    else
      render_form
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @group = current_user.groups.find(params[:id])
    @group.attributes = params[:group]
    return redirect_to edit_group_path(@group) if params[:clear]

    if @group.valid?
      render "confirm"
    else
      render_form
    end
  end

  # 登録データをDBに保存．
  def create
    @group = Group.new(params[:group].merge(:user => current_user))
    return render_form if params[:cancel] || !@group.valid?

    Group.transaction do
      @group.save!
    end

    redirect_to complete_after_create_group_path(@group)
  end

  # 更新データをDBに保存．
  def update
    @group = current_user.groups.find(params[:id])
    @group.attributes = params[:group]
    return render_form if params[:cancel] || !@group.valid?

    Group.transaction do
      @group.save!
    end

    redirect_to complete_after_update_group_path(@group)
  end

  # レコード作成完了画面表示
  def complete_after_create
    @message = "登録完了いたしました。"
    if request.mobile?
      render "/share/complete", :layout => "application"
    else
      render "complete"
    end
  end

  # レコード更新完了画面表示
  def complete_after_update
    @message = "登録修正完了いたしました。"
    if request.mobile?
      render "/share/complete", :layout => "application"
    else
      render "complete"
    end
  end

  # レコード削除確認画面
  def confirm_before_destroy
    @group = current_user.groups.find(params[:id])
  end

  # レコードの削除
  def destroy
    @group = current_user.groups.find(params[:id])
    @group.destroy

    if request.mobile?
      redirect_to complete_after_destroy_groups_path
    else
      redirect_to new_group_path
    end
  end

  # グループメンバーを管理する
  def member_list
    @group = current_user.groups.find(params[:id])
    @friends = current_user.friends.paginate(paginate_options)
  end

  # グループにメンバーを追加する
  def add_friend
    @group = current_user.groups.find(params[:id])
    friend = User.find(params[:user_id])
    flash[:error] = "メンバーを追加できませんでした" unless  @group.add_friend(friend)
    redirect_to member_list_group_path(@group)
  end

  # グループからメンバーを削除する
  def remove_friend
    @group = current_user.groups.find(params[:id])
    friend = User.find(params[:user_id])
    flash[:error] = "メンバーを削除できませんでした" unless @group.remove_friend(friend)
    redirect_to member_list_group_path(@group)
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    friends_path
  end

  private
  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :per_page => (per_page_for_all(User) ? per_page_for_all(User) : 15),
      :order => (params[:order] ? construct_sort_order : User.default_index_order),
    }
  end

  def render_form
    if params[:back_to] == "member_list"
      @friends = current_user.friends.paginate(paginate_options)
      render "member_list"
    else
      @groups = current_user.groups
      render "form"
    end
  end

  # 自分が作成したグループのみ編集・削除やメンバーの追加といった処理が可能
  def group_owner?
    Group.exists?(["id = ? AND user_id = ?", params[:id], current_user.id])
  end

  def load_group
    @group = current_user.groups.find(params[:id])
  end
end

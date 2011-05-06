# コミュニティグループ管理
class CommunityGroupsController < ApplicationController
  layout "communities"

  with_options :redirect_to => :community_groups_url do |con|
    con.verify :params => "id", :only => %w(destroy confirm_before_update)
    con.verify :params => "community_group",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  access_control do
    allow logged_in
    deny all, :unless => :group_owner?,
              :to => %w(edit confirm_before_update update complete_after_update
                         confirm_before_destroy destroy community_list add_community remove_community)
  end

  # 登録フォームの表示．
  def new
    @community_group ||= CommunityGroup.new
    render_form
  end

  # 編集フォームの表示．
  def edit
    @community_group ||= CommunityGroup.find(params[:id])
    render_form
  end

  # 登録確認画面表示
  def confirm_before_create
    @community_group = CommunityGroup.new(params[:community_group].merge(:user => current_user))
    return redirect_to new_community_group_path if params[:clear]

    if @community_group.valid?
      render "confirm"
    else
      render_form
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @community_group = CommunityGroup.find(params[:id])
    @community_group.attributes = params[:community_group]
    return redirect_to edit_community_group_path(@community_group) if params[:clear]

    if @community_group.valid?
      render "confirm"
    else
      render_form
    end
  end

  # 登録データをDBに保存．
  def create
    @community_group = CommunityGroup.new(params[:community_group].merge(:user => current_user))
    return render_form if params[:cancel] || !@community_group.valid?

    CommunityGroup.transaction do
      @community_group.save!
    end

    redirect_to complete_after_create_community_group_path(@community_group)
  end

  # 更新データをDBに保存．
  def update
    @community_group = CommunityGroup.find(params[:id])
    @community_group.attributes = params[:community_group]
    return render "form" if params[:cancel] || !@community_group.valid?

    CommunityGroup.transaction do
      @community_group.save!
    end

    redirect_to complete_after_update_community_group_path(@community_group)
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

  # レコードの削除確認画面（携帯用）
  def confirm_before_destroy
    @community_group = CommunityGroup.find(params[:id])
  end

  # レコードの削除
  def destroy
    @community_group = CommunityGroup.find(params[:id])
    @community_group.destroy

    if request.mobile?
      redirect_to complete_after_destroy_community_groups_path
    else
      redirect_to new_community_group_path
    end
  end

  # コミュニティグループ内のコミュニティを管理する
  def community_list
    @community_group = CommunityGroup.find(params[:id])
    @communities = current_user.communities.paginate(paginate_options)
  end

  # グループにコミュニティを追加する
  def add_community
    @community_group = CommunityGroup.find(params[:id])
    community = Community.find(params[:community_id])
    flash[:error] = "コミュニティを追加できませんでした" unless  @community_group.add_community(community)
    redirect_to community_list_community_group_path(@community_group)
  end

  # グループにコミュニティを削除する
  def remove_community
    @community_group = CommunityGroup.find(params[:id])
    community = Community.find(params[:community_id])
    flash[:error] = "コミュニティを削除できませんでした" unless @community_group.remove_community(community)
    redirect_to community_list_community_group_path(@community_group)
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    logged_in? ? communities_path : search_communities_path
  end

  private
  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : Community.default_index_order),
      :per_page => (per_page_for_all(Community) ? per_page_for_all(Community) : 15),
    }
  end

  def render_form
    if params[:back_to] == "community_list"
      @communities = current_user.communities.paginate(paginate_options)
      render "community_list"
    else
      @community_groups = current_user.community_groups
      render "form"
    end
  end

  # 自分が作成したグループのみ編集・削除やメンバーの追加といった処理が可能
  def group_owner?
    CommunityGroup.exists?(["id = ? AND user_id = ?", params[:id], current_user.id])
  end
end

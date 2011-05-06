# CommunityMapCategories管理
#
# コミュニティカテゴリーを管理する
class CommunityMapCategoriesController < ApplicationController
  layout "communities"

  with_options :redirect_to => :community_map_categories_url do |con|
    con.verify :params => "id", :only => %w(show destroy confirm_before_update)
    con.verify :params => "community_map_category",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  before_filter :load_community

  # 管理人、及び副管理人がアクセス可能
  access_control do
    allow :community_admin, :of => :community
    allow :community_sub_admin, :of => :community
  end

  # 登録フォームの表示．
  def new
    @community_map_category ||= CommunityMapCategory.new
    render_form
  end

  # 編集フォームの表示．
  def edit
    @community_map_category ||= CommunityMapCategory.find(params[:id])
    render_form
  end

  # 登録確認画面表示
  def confirm_before_create
    attributes = {:author => current_user, :community_id => @community.id }
    @community_map_category = CommunityMapCategory.new(params[:community_map_category].merge(attributes))
    return redirect_to new_community_map_category_path if params[:clear]

    if @community_map_category.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @community_map_category = CommunityMapCategory.find(params[:id])
    @community_map_category.attributes = params[:community_map_category]
    return redirect_to edit_community_map_category_path(@community_map_category) if params[:clear]

    if @community_map_category.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 登録データをDBに保存．
  def create
    attributes = {:author => current_user, :community_id => @community.id }
    @community_map_category = CommunityMapCategory.new(params[:community_map_category].merge(attributes))
    return render_form if params[:cancel] || !@community_map_category.valid?

    CommunityMapCategory.transaction do
      @community_map_category.save!
    end

    if request.mobile?
      redirect_to complete_after_create_community_map_category_path(:id => @community_map_category, :community_id => @community.id)
    else
      redirect_to new_community_map_category_path(:community_id => @community.id)
    end
  end

  # 更新データをDBに保存．
  def update
    attributes = {:author => current_user, :community_id => @community.id }
    @community_map_category = CommunityMapCategory.find(params[:id])
    @community_map_category.attributes = params[:community_map_category].merge(attributes)
    return render_form if params[:cancel] || !@community_map_category.valid?

    CommunityMapCategory.transaction do
      @community_map_category.save!
    end

    if request.mobile?
      redirect_to complete_after_update_community_map_category_path(:id => @community_map_category, :community_id => @community)
    else
      redirect_to new_community_map_category_path(:community_id => @community.id)
    end
  end

  # レコードの削除確認画面
  def confirm_before_destroy
    @community_map_category = CommunityMapCategory.find(params[:id])
  end

  # レコードの削除
  def destroy
    @community_map_category = CommunityMapCategory.find(params[:id])
    @community_map_category.destroy

    if request.mobile?
      redirect_to complete_after_destroy_community_map_categories_path(:community_id => @community.id)
    else
      redirect_to new_community_map_category_path(:community_id => @community.id)
    end
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
      :per_page => (per_page_for_all(CommunityMapCategory) ? per_page_for_all(CommunityMapCategory) : params[:per_page]),
      :order => (params[:order] ? construct_sort_order : CommunityMapCategory.default_index_order),
      :include => :author
    }
  end

  def load_community
    @community = Community.find(params[:community_id])
  end

  def render_form
    @map_categories = CommunityMapCategory.community_id_is(@community.id).paginate(:all, paginate_options)
    render "form"
  end
end

# コミュニティリンク管理
class CommunityLinkagesController < ApplicationController

  with_options :redirect_to => :community_linkages_url do |con|
    con.verify :params => "id", :only => %w(destroy)
    con.verify :method => :post, :only => %w(confirm_before_create create)
    con.verify :method => :delete, :only => %w(destroy)
  end

  before_filter :load_community

  access_control do
    allow :community_sub_admin, :community_admin,
    :of => :community,
    :except => :index

    # コミュニティの公開範囲に応じたアクセス制限
    allow :community_sub_admin, :community_admin, :community_general, :to => :index, :of => :community
    allow anonymous, :if => :anoymous_viewable?, :to => :index
    allow logged_in, :if => :login_user_viewable?, :to => :index
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    @community_linkages = @community.linkages.paginate(:all, paginate_options)
  end

  def index_for_admin
    @community_linkages = @community.linkages.paginate(:all, paginate_options)
  end

  # 登録フォームの表示．
  def new
    @community_linkage = CommunityLinkage.construct_linkage(:kind => params[:kind])

    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    attributes = params[:community_inner_linkage] || params[:community_outer_linkage]
    @community_linkage = CommunityLinkage.construct_linkage(attributes.merge(:community_id => @community.id, :user_id => current_user.id))
    return redirect_to new_community_linkage_path(:kind => @community_linkage.kind) if params[:clear]

    if @community_linkage.valid?
      render "confirm"
    else
      render "form"
    end
  end


  # 登録データをDBに保存．
  def create
    attributes = params[:community_inner_linkage] || params[:community_outer_linkage]
    @community_linkage = CommunityLinkage.construct_linkage(attributes.merge(:community_id => @community.id, :user_id => current_user.id))
    return render "form" if params[:cancel] || !@community_linkage.valid?

    CommunityLinkage.transaction do
      @community_linkage.save!
    end

    redirect_to complete_after_create_community_linkage_path(:id => @community_linkage, :community_id => @community.id)
  end

  # レコードの削除確認画面
  # 携帯用
  def confirm_before_destroy
    @community_linkage = CommunityLinkage.find(params[:id])
  end

  # レコードの削除
  # 携帯用
  def destroy
    @community_linkage = CommunityLinkage.find(params[:id])
    @community_linkage.destroy

    redirect_to complete_after_destroy_community_linkages_path(:community_id => @community.id)
  end

  # チェックされたコミュニティリンクを削除する
  def destroy_checked_ids
    linkage_ids_in_community = @community.linkages.map(&:id)
    params[:community_linkage_ids].each do |linkage_id|
      if linkage_ids_in_community.include?(linkage_id.to_i)
        CommunityLinkage.destroy(linkage_id)
      end
    end
    redirect_to index_for_admin_community_linkages_path(:community_id => @community.id)
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
      :order => (params[:order] ? construct_sort_order : CommunityLinkage.default_index_order),
      :per_page => (per_page_for_all(CommunityLinkage) ? per_page_for_all(CommunityLinkage) : 20),
    }
  end

  def load_community
    @community = Community.find(params[:community_id])
  end

  def anoymous_viewable?
    @community.anoymous_viewable?
  end

  def login_user_viewable?
    @community.login_user_viewable?
  end
end

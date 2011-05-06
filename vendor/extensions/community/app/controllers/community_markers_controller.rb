# コミュニティのマーカー情報を管理
class CommunityMarkersController < ApplicationController
  include Mars::GmapSelectable::PC
  include Mars::GmapSelectable::Mobile
  include Mars::GmapViewable::Mobile
  include Mars::UnpublicImageAccessible
  include Mars::Community::CommonController

  unpublic_image_accessible :model_name => :community_thread_attachment

  layout "communities"

  with_options :redirect_to => :community_markers_url do |con|
    con.verify :params => "id", :only => %w(show destroy confirm_before_update)
    con.verify :params => "community_marker",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  before_filter :load_community
  before_filter :verify_marker_createable, :only => %w(new confirm_before_create create)
  before_filter :verify_marker_editable_or_destroyable,
                :only => %w(edit confirm_before_update update confirm_before_destroy destroy)

  access_control do
    # コミュニティの公開範囲に応じたアクセス制限
    allow :community_sub_admin, :community_admin, :community_general, :of => :community
    allow anonymous, :if => :anoymous_viewable?
    allow logged_in, :if => :login_user_viewable?
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    @community_markers = CommunityMarker.paginate(:all, paginate_options)
  end

  # レコードの詳細情報の表示．
  def show
    @community_marker = CommunityMarker.find(params[:id])

    @replies = CommunityReply.thread_id_is(@community_marker.id).deleted_is(false)
    @replies = @replies.paginate(paginate_options_for_reply)

    @title = [@community.name, @community_marker.title].join(" - ")
  end

  # 登録フォームの表示．
  def new
    @community_marker ||= CommunityMarker.new
    render_form
  end

  # 編集フォームの表示．
  def edit
    @community_marker ||= CommunityMarker.find(params[:id])
    render_form
  end

  # 登録確認画面表示
  def confirm_before_create
    @community_marker = CommunityMarker.new(params[:community_marker])
    @community_marker.author = current_user
    @community_marker.community_id = params[:community_id]

    return redirect_to new_community_marker_path if params[:clear]

    # 住所検索
    if search_address_request_for_mobile?
      return render_form
    end

    if @community_marker.valid?
      set_unpublic_image_uploader_keys(@community_marker)
      render "confirm"
    else
      render_form
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @community_marker = CommunityMarker.find(params[:id])
    @community_marker.attributes = params[:community_marker]

    return redirect_to edit_community_marker_path(:id => @community_marker, :community_id => @community_marker.community_id) if params[:clear]

    # 住所検索
    if search_address_request_for_mobile?
      return render_form
    end

    if @community_marker.valid?
      set_unpublic_image_uploader_keys(@community_marker)
      render "confirm"
    else
      render_form
    end
  end

  # 登録データをDBに保存．
  def create
    @community_marker = CommunityMarker.new(params[:community_marker])
    @community_marker.author = current_user
    @community_marker.community_id = params[:community_id]

    return render_form if params[:cancel] || !@community_marker.valid?

    CommunityMarker.transaction do
      @community_marker.save!
    end

    redirect_to complete_after_create_community_marker_path(:id => @community_marker, :community_id => @community)
  end

  # 更新データをDBに保存．
  def update
    @community_marker = CommunityMarker.find(params[:id])
    @community_marker.attributes = params[:community_marker]
    return render_form if params[:cancel] || !@community_marker.valid?

    CommunityMarker.transaction do
      @community_marker.save!
    end

    redirect_to complete_after_update_community_marker_path(:id => @community_marker, :community_id => @community_marker.community_id)
  end

  # レコードの削除確認画面（携帯用）
  def confirm_before_destroy
    return redirect_to communities_url unless request.mobile?
    render :partial => "/share/confirm_before_destroy_thread", :layout => "communities"
  end

  # レコードの削除
  def destroy
    @community_marker = CommunityMarker.find(params[:id])
    community_id = @community_marker.community_id
    @community_marker.destroy

    if request.mobile?
      redirect_to community_threads_path(:id => community_id)
    else
      redirect_to search_community_threads_path(:community_id => community_id)
    end
  end

  # コミュニティマップ表示
  def map
    respond_to do |type|
      type.html do
        @community_markers = @community.markers.group_by(&:community_map_category_id).sort_by{|a| a.first}
        return
      end
      if @community.visibility_public?
        # FIXME: 実機で、CommunityMarker.community_id_is(@community.id)とすると、NoMethodError (undefined method `call' for nil:NilClass):というエラーがでる
        # テスト環境では同様のデータを使用しても再現せず、原因は不明で、search_logicを使用しないように修正
        @threads = CommunityMarker.find(:all, :conditions => ["community_id = ?", @community.id],
                                        :limit => 10,
                                        :order => "created_at DESC")

        @xml_title = "#{@community.name} - #{SnsConfig.title}"
        @xml_link = community_path(@community)
        @carwings = true
        @time = "created_at"
        type.rdf { render "communities/feed.rdf.builder"}
        type.rss { render "communities/feed.rxml" }
        type.atom { render "communities/feed.atom.builder" }
      end
    end
  end

  # コミュニティマップカテゴリ一覧表示（携帯用）
  def list_category
    @title = @community.name + " - " + "コミュニティマップ"
    @community_markers = @community.map_categories
  end

  # カテゴリごとのコミュニティマップ表示（携帯用）
  def map_for_mobile
    @title = @community.name + " - " + "コミュニティマップ"
    set_map_for_mobile_params
    @community_map_category = CommunityMapCategory.find params[:community_map_category_id]
    @records = CommunityMarker.community_map_category_id_is(params[:community_map_category_id]).
      by_latitude_range(@latitude_start, @latitude_end).
      by_longitude_range(@longitude_start, @longitude_end).
      paginate(paginate_options)
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
      :order => (params[:order] ? construct_sort_order : CommunityMarker.default_index_order),
      :per_page => (request.mobile? ? 5 : 10)
    }
  end

  def load_community
    if params[:community_id] && Community.exists?(params[:community_id])
      @community = Community.find(params[:community_id])
    end
  end

  # マーカー作成の権限があるかどうか検証し、無ければトップページへ飛ばす
  def verify_marker_createable
    redirect_to root_path  unless @community.try(:topic_and_marker_createable?, current_user)
  end

  # マーカー編集の権限があるかどうか検証し、無ければトップページへ飛ばす
  def verify_marker_editable_or_destroyable
    if params[:id] && CommunityMarker.exists?(params[:id])
      redirect_to root_path unless CommunityMarker.find(params[:id]).editable?(current_user)
    else
      redirect_to root_path
    end
  end

  # ファイルアップロードキー設定
  def set_unpublic_image_uploader_keys(thread)
    thread.attachments.each do |at|
      self.unpublic_image_uploader_key = at.image_temp unless at.image_temp.blank?
    end
  end

  def render_form
    @community_marker.build_attachments
    render "form"
  end
end

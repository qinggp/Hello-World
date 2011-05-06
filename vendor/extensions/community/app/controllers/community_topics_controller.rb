# コミュニティのトピック情報を管理
class CommunityTopicsController < ApplicationController
  include Mars::UnpublicImageAccessible
  include Mars::Community::CommonController

  unpublic_image_accessible :model_name => :community_thread_attachment

  with_options :redirect_to => :community_topics_url do |con|
    con.verify :params => "id", :only => %w(show destroy confirm_before_update)
    con.verify :params => "community_topic",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  layout "communities"

  before_filter :load_community
  before_filter :verify_topic_createable, :only => %w(new confirm_before_create create)
  before_filter :verify_topic_editable_or_destroyable,
                :only => %w(edit confirm_before_update update confirm_before_destroy destroy)

  access_control do
    # コミュニティの公開範囲に応じたアクセス制限
    allow :community_sub_admin, :community_admin, :community_general, :of => :community
    allow anonymous, :if => :anoymous_viewable?
    allow logged_in, :if => :login_user_viewable?
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    @community_topics = CommunityTopic.paginate(:all, paginate_options)
  end

  # レコードの詳細情報の表示．
  def show
    @community_topic = CommunityTopic.find(params[:id])

    @replies = CommunityReply.thread_id_is(@community_topic.id).deleted_is(false)
    @replies = @replies.paginate(paginate_options_for_reply)

    @title = [@community.name, @community_topic.title].join(" - ")
  end

  # 登録フォームの表示．
  def new
    @community_topic ||= CommunityTopic.new(:author => current_user)
    render_form
  end

  # 編集フォームの表示．
  def edit
    @community_topic ||= CommunityTopic.find(params[:id])
    render_form
  end

  # 編集フォームの表示．
  def edit
    @community_topic ||= CommunityTopic.find(params[:id])
    render_form
  end

  # 登録確認画面表示
  def confirm_before_create
    @community_topic = CommunityTopic.new(params[:community_topic])
    @community_topic.author = current_user
    @community_topic.community_id = params[:community_id]

    return redirect_to new_community_topic_path if params[:clear]

    if @community_topic.valid?
      set_unpublic_image_uploader_keys(@community_topic)
      render "confirm"
    else
      render_form
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @community_topic = CommunityTopic.find(params[:id])
    @community_topic.attributes = params[:community_topic]

    return redirect_to edit_community_topic_path(:id => @community_topic, :community_id => @community_topic.community.id) if params[:clear]

    if @community_topic.valid?
      set_unpublic_image_uploader_keys(@community_topic)
      render "confirm"
    else
      render_form
    end
  end

  # 登録データをDBに保存．
  def create
    @community_topic = CommunityTopic.new(params[:community_topic])
    @community_topic.author = current_user
    @community_topic.community_id = params[:community_id]

    return render_form if params[:cancel] || !@community_topic.valid?

    CommunityTopic.transaction do
      @community_topic.save!
    end

    clear_unpublic_image_uploader_key
    redirect_to complete_after_create_community_topic_path(:community_id => @community, :id => @community_topic)
  end

  # 更新データをDBに保存．
  def update
    @community_topic = CommunityTopic.find(params[:id])
    @community_topic.attributes = params[:community_topic]
    return render_form if params[:cancel] || !@community_topic.valid?

    CommunityTopic.transaction do
      @community_topic.save!
    end

    clear_unpublic_image_uploader_key
    redirect_to complete_after_update_community_topic_path(:id => @community_topic, :community_id => @community_topic.community_id)
  end

  # レコードの削除確認画面（携帯用）
  def confirm_before_destroy
    return redirect_to communities_url unless request.mobile?
    render :partial => "/share/confirm_before_destroy_thread", :layout => "communities"
  end

  # レコードの削除
  def destroy
    @community_topic = CommunityTopic.find(params[:id])
    community_id = @community_topic.community_id
    @community_topic.destroy

    if request.mobile?
      redirect_to community_threads_path(:id => community_id)
    else
      redirect_to search_community_threads_path(:community_id => community_id)
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
      :order => (params[:order] ? construct_sort_order : CommunityTopic.default_index_order),
    }
  end

  def load_community
    if params[:community_id] && Community.exists?(params[:community_id])
      @community = Community.find(params[:community_id])
    end
  end

  # トピック作成の権限があるかどうか検証し、無ければトップページへ飛ばす
  def verify_topic_createable
    redirect_to root_path  unless @community.try(:topic_and_marker_createable?, current_user)
  end

  # トピック編集の権限があるかどうか検証し、無ければトップページへ飛ばす
  def verify_topic_editable_or_destroyable
    if params[:id] && CommunityTopic.exists?(params[:id])
      redirect_to root_path unless CommunityTopic.find(params[:id]).editable?(current_user)
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
    @community_topic.build_attachments
    render "form"
  end
end

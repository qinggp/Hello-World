# コミュニティへの書き込み（マーカー、トピック、イベント）の一覧を表示するコントローラ
class CommunityThreadsController < ApplicationController
  include Mars::UnpublicImageAccessible
  unpublic_image_accessible :model_name => :community_thread_attachment

  before_filter :load_community

  access_control do
    public_actions = %w(index search show_comment_tree show_comment_tree_specified_thread)
    allow all, :if => :visibility_public?,  :to => public_actions
    allow logged_in, :if => :visibility_member?,
          :to => public_actions
    allow :community_general, :community_sub_admin, :community_admin,
          :if => :visibility_private_or_secret?, :of => :community,
          :to => public_actions
  end

  layout "communities"

  # トピック、イベント、マーカーいずれかの一覧表示画面
  def index
    type_name = params[:types].first if params[:types]
    @thread_class = CommunityThread.class_by_type(type_name)
    @title = "#{@community.name} - #{@thread_class.human_name}"

    @community_threads = CommunityThread.community_id_is(@community.id)
    scope_by_types
    scope_by_event_date_during_a_month if @thread_class == CommunityEvent
    @community_threads = @community_threads.paginate(paginate_options)
  end

  # トピック検索結果画面
  # 名前はトピック検索だが、マーカー、トピック、イベントを対象としている
  def search
    @community_threads = CommunityThread.community_id_is(@community.id)
    scope_by_types
    scope_by_keyword
    scope_by_event_date
    @community_threads = @community_threads.paginate(paginate_options)
  end

  # コミュニティに紐づくcommunity_topic、community_eventとその返信をツリー表示する
  def show_comment_tree
    @community_threads = CommunityThread.community_id_is(@community.id)
    scope_by_types
    @community_threads = @community_threads.paginate(paginate_options)
  end

  # ある特定のスレッドにある返信をツリー表示する
  def show_comment_tree_specified_thread
    @community_thread = CommunityThread.community_id_is(@community.id).id_is(params[:id]).first
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    logged_in? ? communities_path : search_communities_path
  end

  private
  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :include => :author,
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :per_page => (per_page_for_all(CommunityThread) ? per_page_for_all(CommunityThread) : 10),
      :order => (params[:order] ? construct_sort_order : "community_threads.lastposted_at DESC"),
    }
  end

  def load_community
    @community = Community.find(params[:community_id])
  end

  def scope_by_types
    types = params[:types].blank? ? ["CommunityTopic", "CommunityEvent"] : params[:types]
    @community_threads = @community_threads.type_is_any(types)
  end

  def scope_by_keyword
    @community_threads = @community_threads.title_or_content_like(params[:keyword])
  end

  def scope_by_event_date
    @community_threads = @community_threads.event_date_is(params[:event_date]) unless params[:event_date].blank?
  end

  def scope_by_event_date_during_a_month
    if Date.valid_date?(params[:year].to_i, params[:month].to_i, 1)
      @start_date = Date.civil(params[:year].to_i, params[:month].to_i, 1)
    else
      @start_date = Date.today.beginning_of_month
    end
    @community_threads = @community_threads.
      event_date_greater_than_or_equal_to(@start_date).
      event_date_less_than_or_equal_to(@start_date.end_of_month)
  end

  def visibility_public?
    @community.visibility_public?
  end

  def visibility_member?
    @community.visibility_member?
  end

  def visibility_private_or_secret?
    @community.visibility_private? || @community.visibility_secret?
  end
end

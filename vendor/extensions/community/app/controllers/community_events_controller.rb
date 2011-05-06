# コミュニティのイベント情報を管理
class CommunityEventsController < ApplicationController
  include Mars::UnpublicImageAccessible
  include Mars::CalendarViewable
  include Mars::GmapSelectable::PC
  include Mars::GmapSelectable::Mobile
  include Mars::Messageable
  include Mars::Community::CommonController

  layout "communities"

  unpublic_image_accessible :model_name => :community_thread_attachment

  with_options :redirect_to => :community_events_url do |con|
    con.verify :params => "id", :only => %w(show destroy confirm_before_update)
    con.verify :params => "community_event",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  before_filter :load_community, :except => %w(show_calendar list_on_date)
  before_filter :verify_event_createable, :only => %w(new confirm_before_create create)
  before_filter :verify_event_editable_or_destroyable,
                :only => %w(edit confirm_before_update update confirm_before_destroy destroy)

  access_control do
    # コミュニティの公開範囲とイベントの公開範囲に応じたアクセス制限
    allow :community_sub_admin, :community_admin, :community_general, :of => :community
    allow anonymous, :if => :anoymous_viewable?, :unless => :event_not_publiced?
    allow logged_in, :if => :login_user_viewable?, :unless => :event_not_publiced?
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    @community_events = CommunityEvent.paginate(:all, paginate_options)
  end

  # レコードの詳細情報の表示．
  def show
    @community_event = CommunityEvent.find(params[:id])

    @replies = CommunityReply.thread_id_is(@community_event.id).deleted_is(false)
    @replies = @replies.paginate(paginate_options_for_reply)

    @title = [@community.name, @community_event.title].join(" - ")
  end

  # 登録フォームの表示．
  def new
    @community_event ||= CommunityEvent.new(:public => true)
    if params[:event_date]
      @community_event.event_date = params[:event_date]
    end
    render_form
  end

  # 編集フォームの表示．
  def edit
    @community_event ||= CommunityEvent.find(params[:id])
    render_form
  end

  # 登録確認画面表示
  def confirm_before_create
    attributes =
      params[:community_event].merge(:author => current_user,
                                     :community_id => @community.id)
    @community_event = CommunityEvent.new(attributes)

    return redirect_to new_community_event_path if params[:clear]

    # 住所検索
    if search_address_request_for_mobile?
      return render_form
    end

    if @community_event.valid?
      set_unpublic_image_uploader_keys(@community_event)
      render "confirm"
    else
      render_form
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @community_event = CommunityEvent.find(params[:id])
    @community_event.attributes = params[:community_event]

    return redirect_to edit_community_event_path(:id => @community_event, :community_id => @community_event.community_id) if params[:clear]

    # 住所検索
    if search_address_request_for_mobile?
      return render_form
    end

    if @community_event.valid?
      set_unpublic_image_uploader_keys(@community_event)
      render "confirm"
    else
      render_form
    end
  end

  # 登録データをDBに保存．
  def create
    @community_event =
      CommunityEvent.new(params[:community_event].merge(:author => current_user,
                                                        :community_id => @community.id))

    return render_form if params[:cancel] || !@community_event.valid?
    CommunityEvent.transaction do
      @community_event.save!
    end

    clear_unpublic_image_uploader_key
    redirect_to complete_after_create_community_event_path(:community_id => @community.id, :id => @community_event)
  end

  # 更新データをDBに保存．
  def update
    @community_event = CommunityEvent.find(params[:id])
    @community_event.attributes = params[:community_event]

    return render_form if params[:cancel] || !@community_event.valid?

    CommunityEvent.transaction do
      @community_event.save!
    end

    clear_unpublic_image_uploader_key
    redirect_to complete_after_update_community_event_path(:id => @community_event, :community_id => @community_event.community_id)
  end

  # レコードの削除確認画面（携帯用）
  def confirm_before_destroy
    return redirect_to communities_url unless request.mobile?
    render :partial => "/share/confirm_before_destroy_thread", :layout => "communities"
  end

  # レコードの削除
  def destroy
    @community_event = CommunityEvent.find(params[:id])
    community_id = @community_event.community_id
    @community_event.destroy

    if request.mobile?
      redirect_to community_threads_path(:id => community_id)
    else
      redirect_to search_community_threads_path(:community_id => community_id)
    end
  end

  # コミュニティイベント参加者一覧表示
  def show_members
    @community_event = CommunityEvent.find(params[:id])
    @members = @community_event.participations.paginate(paginate_options_for_member)
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    logged_in? ? communities_path : search_communities_path
  end

  # ある特定の日付のイベント一覧を表示する
  # カレンダーからの遷移なので、非公開やないしょに属するコミュニティのイベントは表示されない
  # ログインしていなくても誰でも見れるが、この場合外部公開コミュニティのみが対象
  def list_on_date
    @date = Date.parse(params[:date])
    if logged_in?
      @community_events = CommunityEvent.on_calendar.event_date_is(@date).paginate(paginate_options)
    else
      @community_events = CommunityEvent.on_calender_for_outer.event_date_is(@date).paginate(paginate_options)
    end

    @title = l(@date, :format => :year_month_date) + "のイベント一覧"
  end

  private
  # イベント一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :per_page => (params[:per_page] ? per_page_for_all(CommunityEvent) : 10),
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : CommunityEvent.default_index_order),
    }
  end

  def load_community
    if params[:community_id] && Community.exists?(params[:community_id])
      @community = Community.find(params[:community_id])
    end
  end

  # カレンダー表示に必要なパラメータ設定
  def set_calendar_params
    if params[:community_id]
      @community = Community.find(params[:community_id])
      @community_events = @community.events
    else
      if logged_in?
        @community_events = CommunityEvent.on_calendar
      else
        @community_events = CommunityEvent.on_calender_for_outer
      end
      @events_on_today = @community_events.open.all.sort_by{ rand }.slice(0, 3)
    end
  end

  # イベント作成の権限があるかどうか検証し、無ければトップページへ飛ばす
  def verify_event_createable
    redirect_to root_path  unless @community.try(:event_createable?, current_user)
  end

  # イベント編集の権限があるかどうか検証し、無ければトップページへ飛ばす
  def verify_event_editable_or_destroyable
    if params[:id] && CommunityEvent.exists?(params[:id])
      redirect_to root_path unless CommunityEvent.find(params[:id]).editable?(current_user)
    else
      redirect_to root_path
    end
  end

  # イベントがコミュニティ内のみの公開制限であるかどうか
  def event_not_publiced?
    if params[:id] && CommunityEvent.exists?(params[:id])
      return !CommunityEvent.find(params[:id]).public?
    end
    false
  end

  # コミュニティメンバーであるかどうか
  def not_community_member?
    !@community.member?(current_user)
  end

  # ファイルアップロードキー設定
  def set_unpublic_image_uploader_keys(thread)
    thread.attachments.each do |at|
      self.unpublic_image_uploader_key = at.image_temp unless at.image_temp.blank?
    end
  end

  def render_form
    @community_event.build_attachments
    render "form"
  end
end

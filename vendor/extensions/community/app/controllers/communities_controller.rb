class CommunitiesController < ApplicationController
  include Mars::UnpublicImageAccessible
  include Mars::GmapSelectable::PC
  include Mars::GmapSelectable::Mobile
  include Mars::CalendarViewable
  include Mars::Messageable
  include Mars::Community::CommonController

  unpublic_image_accessible :model_name => :community

  layout "communities"

  # ソート対象を表す定数
  POSTED_AT = 1
  CREATED_AT = 2
  NAME = 3
  MEMBER_COUNT = 4
  TOPIC_COUNT = 5
  EVENT_COUNT = 6
  MARKER_COUNT = 7

  # 昇順降順を表す定数
  ASC = 1
  DESC = 2

  before_filter :mobile_only, :only => [:show_detail]

  before_filter :load_community,
                :except => [:index, :search, :new, :confirm_before_create,
                           :create, :display_file]

  access_control do
    allow all, :to => [:open_map, :index_feed, :index_feed_for, :map, :select_map]

    allow logged_in,
          :to => [:index, :new, :confirm_before_create,
                  :create, :confirm_before_apply, :apply,
                  :complete_after_destroy, :recent_posts]

    allow :community_admin, :of => :community,
          :to => [:edit, :confirm_before_update, :update,
                  :confirm_before_destroy, :destroy,
                  :show_application, :approve_or_reject,
                  :complete_after_create, :complete_after_update]

    allow :community_sub_admin, :of => :community,
          :to => [:confirm_before_cancel, :cancel,
                  :show_application, :approve_or_reject]

    allow :community_general, :of => :community,
          :to => [:confirm_before_cancel, :cancel]

    allow :community_general, :community_sub_admin, :community_admin,
          :of => :community,
          :to => [:new_message, :confirm_before_create_message, :create_message, :complete_after_create_message]


    deny :community_general, :community_sub_admin, :community_admin,
         :of => :community,
         :to => [:confirm_before_apply, :apply]

    # コミュニティトップページ、及びその下のページは公開制限によりアクセス権限が変わる
    restricted_actions = [:show, :show_detail, :show_members, :update_comment_notice_acceptable]
    allow all, :if => :visibility_public?,
          :to => restricted_actions
    allow logged_in, :if => :visibility_member?,
          :to => restricted_actions
    allow :community_general, :community_sub_admin, :community_admin,
          :of => :community,
          :to => restricted_actions

    # ログインしてれば、非公開でもコミュニティのトップは見れる
    allow logged_in, :if => :visibility_private?, :to => :show

    allow all, :to => [:search, :show_unpublic_image, :show_unpublic_image_temp, :show_calendar]
  end


  # メンバーが参加しているコミュニティ一覧表示画面
  # または、メンバーが管理しているコミュニティ一覧画面
  def index
    @user = displayed_user || current_user
    @community_groups = @user.community_groups
    @title = "#{@user.name}さんの参加コミュニティ一覧 "
    if params[:community_group_id]
      @community_group = CommunityGroup.find params[:community_group_id]
      @communities = @community_group.communities.paginate(paginate_options)
    elsif params[:role] == "admin"
      @communities = CommunityMembership.admin_communities(@user).paginate(paginate_options)
    else
      @communities = @user.communities.paginate(paginate_options)
    end
  end

  # 新着コミュニティフィード配信
  def index_feed
    @time = "lastposted_at"
    @threads = Community.publiced_threads_order_by_post(:limit => 20)
    @xml_title = "#{SnsConfig.title}新着コミュニティトピック"
    @xml_link = search_communities_url
    respond_to do |type|
      type.rdf { render "feed.rdf.builder"}
      type.rss { render "feed.rxml" }
      type.atom { render "feed.atom.builder" }
    end
  end

  # コミュニティ
  def index_feed_for
    community = Community.find(params[:id])
    if community.visibility_public?
      @time = "created_at"
      @threads = community.threads_and_comments_order_by_post(10)
      @xml_title = "#{community.name} - #{SnsConfig.title}"
      @xml_link = community_path(community)
      respond_to do |type|
        type.rdf { render "feed.rdf.builder" }
        type.rss { render "feed.rxml" }
        type.atom { render "feed.atom.builder" }
      end
    end
  end

  # コミュニティ検索画面
  def search
    @communities = Community.not_secret
    if params[:type] == "official"
      @communities = @communities.official
    else
      scope_by_keyword
      scope_by_category
    end
    @communities = @communities.public unless logged_in?

    @communities = @communities.paginate(paginate_options_for_search.merge(:include => :threads))
    @official_communities = Community.official.not_secret.find(:all,
                                                               :limit => 6)
  end

  # コミュニティ新規作成画面
  def new
    @community = Community.new(:event_createable_admin_only => false,
                               :topic_createable_admin_only => false,
                               :participation_notice => true)
    render_form
  end

  # コミュニティ設定変更画面
  def edit
    @community = Community.find(params[:id])
    render_form
  end

  # コミュニティ新規作成確認画面
  def confirm_before_create
    @community = Community.new(params[:community])

    return redirect_to new_community_path if params[:clear]

    # 住所検索
    if search_address_request_for_mobile?
      return render_form
    end

    if @community.valid?
      set_unpublic_image_uploader_keys(@community)
      render "confirm"
    else
      @community.image = nil
      render "form"
    end
  end

  # コミュニティ設定変更確認画面
  def confirm_before_update
    @community = Community.find(params[:id])

    return redirect_to edit_community_path(@community) if params[:clear]

    @community.attributes = params[:community]

    # 住所検索
    if search_address_request_for_mobile?
      return render_form
    end

    if @community.valid?
      set_unpublic_image_uploader_keys(@community)
      render "confirm"
    else
      render "form"
    end
  end

  # コミュニティ作成
  def create
    @community = Community.new(params[:community])

    return render_form if params.has_key?(:cancel) || !@community.valid?

    @user = User.find(session[:user_id])
    Community.transaction do
      @community.save!
      CommunityMembership.create!(:user_id => @user.id,
                                  :community_id => @community.id)
      @user.has_role!(:community_admin, @community)
      Community.add_member_to_official_admin_only(@user)
    end

    redirect_to complete_after_create_community_path(@community)
  end

  # コミュニティ設定変更
  def update
    @community = Community.find(params[:id])
    @community.attributes = params[:community]

    return render_form if params.has_key?(:cancel) || !@community.valid?

    Community.transaction do
      @community.save!
    end

    redirect_to complete_after_update_community_path(:id => @community.id)
  end

  # コミュニティトップ画面
  def show
    render_show
  end

  # 携帯用コミュニティ詳細画面
  def show_detail
    @title = "コミュニティ詳細"

    @community = Community.find(params[:id])
    @community_admin = @community.admin
    @membership = CommunityMembership.user_id_is(current_user.id).community_id_is(@community.id).first
  end

  # コミュニティ削除確認画面
  def confirm_before_destroy
    @community = Community.find(params[:id])

    return render_form if params.has_key?(:cancel)
  end

  # コミュニティ削除
  def destroy
    if params[:id] && Community.exists?(params[:id])
      if params.has_key?(:cancel)
        redirect_to edit_community_path(params[:id])
        return
      end

      admin = @community.admin
      if Community.destroy(params[:id])
        Community.remove_member_from_official_admin_only(admin)
        redirect_to complete_after_destroy_new_community_path
      else
        flash[:error] = "削除失敗しました。"
        redirect_to community_path(params[:id])
      end
    end
  end

  def confirm_before_apply
    @title = "コミュニティ表示"

    if request.mobile?
      @community_admin = @community.admin
    else
      render_show
    end
  end

  def apply
    if params[:id] && Community.exists?(params[:id])
      @community = Community.find(params[:id])
      @user = User.find(session[:user_id])
      CommunityMembership.transaction do
        @community.receive_application(@user, params[:message])
      end
      redirect_to community_path(params[:id])
    else
      redirect_to communities_path
    end
  end

  def confirm_before_cancel
    @title = "コミュニティ退会"

    if request.mobile?
      @community_admin = @community.admin
    else
      render_show
    end
  end

  def cancel
    @title = "コミュニティ退会"

    if params[:id] && Community.exists?(params[:id])
      @community = Community.find(params[:id])
      @user = User.find(session[:user_id])
      CommunityMembership.transaction do
        @community.remove_member!(@user)
      end
      redirect_to community_path(params[:id])
    else
      redirect_to communities_path
    end
  end

  def show_application
    @title = "コミュニティ表示"

    @pending = PendingCommunityUser.find(params[:pending_id])
    @community_admin = @community.admin
    if request.mobile?
      render "show_application"
    else
      render_show
    end
  end

  def approve_or_reject
    @title = "コミュニティ表示"

    @pending = PendingCommunityUser.find(params[:pending_id])
    if params.has_key?(:approve)
      @pending.update_attributes!(:judge_id => current_user.id)
      @pending.activate!
    elsif params.has_key?(:reject)
      @pending.update_attributes!(:reject_message => params[:message],
                                  :judge_id => current_user.id)
      @pending.reject!
    end
    redirect_to community_path(params[:id])
  end

  def open_map
    @key = SnsConfig.g_map_api_key
    @model = params[:model]
    render "share/_map", :layout => false
  end

  # メンバー一覧を表示する
  # メンバー管理で表示する一覧とはまた別
  def show_members
    @members = @community.members.paginate(paginate_options_for_member)
  end

  # コミュニティへの書き込み通知設定を変更する
  def update_comment_notice_acceptable
    attr = params[:community_membership]
    unless @community.update_comment_notice_acceptable(@current_user, attr)
      flash[:error] = "書き込み通知設定に失敗しました"
    end
    if request.mobile?
      redirect_to show_detail_community_path(@community)
    else
      redirect_to community_path(@community)
    end
  end

  # 参加しているコミュニティの最新書込一覧を表示する
  def recent_posts
    @threads = Community.threads_order_by_post_paginate(current_user,
                                                        {:days_ago => params[:days_ago].to_i}, paginate_options_for_thread)
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    logged_in? ? communities_path : search_communities_path
  end

  private
  def load_community
    if Community.exists?(params[:id])
      @community = Community.find(params[:id])
    end
  end

  def visibility_public?
    @community.visibility_public?
  end

  def visibility_member?
    @community.visibility_member?
  end

  def visibility_private?
    @community.visibility_private?
  end

  # ファイルアップロードキー設定
  def set_unpublic_image_uploader_keys(community)
    self.unpublic_image_uploader_key = community.image_temp unless community.image_temp.blank?
  end

  # カレンダー表示に必要なパラメータ設定
  def set_calendar_params
    @community_events = @community.events
  end

  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : Community.default_index_order),
      :per_page => (params[:per_page] ? per_page_for_all(Community) : 30)
    }
  end

  # コミュニティ検索画面の一覧表示オプション
  def paginate_options_for_search
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : Community.default_index_order),
      :per_page => (params[:per_page] ? per_page_for_all(Community) : 10)
    }
  end

  # コミュニティをトモダチに招待する際に、フォームから入力した内容を加工する
  def decorate(message)
    @body = message.body
    message.body = render_to_string(:partial => "/communities/mail/invite_friend", :layout => false)
  end

  # コミュニティをトモダチに招待した際にメールを送信する
  # 承認制である場合、そのユーザを招待状態にする
  def send_mail(message, receivers)
    receivers.each do |receiver|
      message.receiver = receiver
      MessageNotifier.deliver_notification_by_row_message(message)
      if (@community.admin?(current_user) || @community.sub_admin?(current_user)) &&
          !@community.member?(receiver) && @community.approval_required?
        PendingCommunityUser.create(:state => "invited", :user => receiver, :community => @community)
      end
    end
  end

  # 「コミュニティをトモダチに紹介」フォームで、「全てクリア」したときの挙動
  def response_for_confirm_before_create_message_at_clear
     redirect_to :action => :new_message, :id => params[:id]
  end

  # カテゴリによるコミュニティの絞り込み
  def scope_by_category
    unless params[:community_category_id].blank?
      @communities = @communities.community_category_id_is(params[:community_category_id])
    end
  end

  # キーワードによるコミュニティの絞り込み
  def scope_by_keyword
    unless params[:keyword].blank?
      @communities = @communities.name_or_comment_like(params[:keyword])
    end
  end

  def render_form
    if params[:community]
      params[:community].delete(:image_temp)
      params[:community].delete(:delete_image)
      if @community.new_record?
        @community = Community.new(params[:community])
      else
        @community = Community.find(@community.id)
        @community.attributes = params[:community]
      end
    end
    render "form"
  end

  def render_show
    @user = current_user
    @community = Community.find(params[:id])
    @community_members =
      @community.members.find(:all,
                              :order => User.default_index_order,
                              :limit => 12)
    @events = @community.events.find(:all, :limit => 10, :order => "lastposted_at DESC")
    @topics = @community.topics.find(:all, :limit => 10, :order => "lastposted_at DESC")
    @markers =  @community.markers.find(:all, :limit => 10, :order => "lastposted_at DESC")

    @community_admin = @community.admin
    @events_on_today = @community.events.open

    @linkages = @community.linkages
    @membership = CommunityMembership.user_id_is(current_user.id).community_id_is(@community.id).first

    set_calendar_params
    render "show"
  end
end


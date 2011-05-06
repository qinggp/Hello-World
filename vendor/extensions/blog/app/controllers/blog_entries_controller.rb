# -*- coding: utf-8 -*-
# ブログ管理
class BlogEntriesController < ApplicationController
  include Mars::UnpublicImageAccessible
  include Mars::CalendarViewable
  include Mars::GmapSelectable::PC
  include Mars::GmapSelectable::Mobile
  include Mars::GmapViewable::Mobile

  unpublic_image_accessible :model_name => :blog_attachment

  before_filter :set_blog_entry, :only => %w(show edit
                                             confirm_before_update
                                             update complete_after_update
                                             destroy confirm_before_destroy
                                             show_unpublic_image)
  before_filter :set_user
  before_filter :set_blog_title, :only => %w(index_for_user search_for_user show)

  with_options :redirect_to => :root_url do |con|
    con.verify :params => [:user_id], :only => %w(index_for_user search_for_user)
    con.verify :params => "id", :only => %w(destroy confirm_before_update)
    con.verify :params => "blog_entry",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :params => "key", :only => %w(relate_old_user_id_to_current relate_old_blog_id_to_current)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  access_control do
    public_actions = %w(index_feed index_for_user show search search_for_user
                        spread_backnumber show_calendar map map_for_mobile index_for_map
                        not_friend_error search_for_user_mobile backnumber_mobile
                        index_feed_for_user select_map show_unpublic_image relate_old_blog_id_to_current
                        relate_old_user_id_to_current)
    allow all, :to => public_actions
    allow logged_in, :to => %w(new confirm_before_create create search_for_friends
                               complete_after_create change_html_editor
                               switch_html_editor show_unpublic_image_temp)

    allow :blog_entry_author, :of => :blog_entry,
                              :to => %w(show destroy confirm_before_destroy
                                        edit confirm_before_update
                                        update complete_after_update show_unpublic_image)

    deny anonymous, :except => public_actions

    # ブログエントリの公開範囲に応じたアクセス制限
    deny anonymous, :unless => :anonymous_viewable?, :to => %w(show_unpublic_image)
    deny logged_in, :unless => :member_viewable?, :to => %w(show_unpublic_image)
  end

  # ブログ閲覧制限フィルタ
  before_filter :check_viewable_user_filter, :only => :index_for_user
  before_filter :check_viewable_entry_filter, :only => :show

  # 新着ブログ一覧配信
  def index_feed
    @blog_entries =
      BlogEntry.visibility_is(BlogPreference::VISIBILITIES[:publiced]).
        descend_by_created_at.find(:all, :limit => 20)
    @xml_title = "#{SnsConfig.title}新着ブログ"
    @xml_link = search_blog_entries_url
    respond_to do |type|
      type.rdf { render "feed.rdf.builder"}
      type.rss { render "feed.rxml" }
      type.atom { render "feed.atom.builder" }
    end
  end

  # ブログ検索
  def search
    @blog_entries = BlogEntry.by_activate_users
    if logged_in?
      @blog_entries = @blog_entries.by_sns_member_visible
    else
      @blog_entries = @blog_entries.by_visible(nil, false)
    end
    search_blog_entries
    @blog_entries = @blog_entries.paginate(paginate_options)
  end

  # トモダチブログ検索
  def search_for_friends
    @blog_entries =
      BlogEntry.by_user_friends(current_user).
       by_visible(current_user, false)
    search_blog_entries
    @blog_entries = @blog_entries.paginate(paginate_options)
  end

  # 指定ユーザのブログ一覧表示
  #
  # ==== 引数
  #
  # * params[:user_id] - ブログを所有するユーザID
  # * params[:year] - バックナンバ用
  # * params[:month]
  # * params[:blog_category_id] - カテゴリID
  def index_for_user
    @user = User.find(params[:user_id])
    @blog_entries = BlogEntry.by_visible(current_user).by_user(@user)
    all_entry_size = @blog_entries.size

    scope_by_date
    scope_by_category
    set_calendar_params
    search_blog_entries

    # 外部RSSのデータをマージ
    if all_entry_size == @blog_entries.size &&
        !@user.preference.blog_preference.rss_url.blank?
      @blog_entries = BlogEntry.merge_imported_entries_by_rss(
          @user.preference.blog_preference.rss_url, @blog_entries)
    end

    @blog_entries = @blog_entries.paginate(paginate_options)
  end
  alias :search_for_user_mobile :index_for_user
  alias :backnumber_mobile :index_for_user
  alias :show_calendar :index_for_user

  # ユーザを指定するブログ記事
  def index_feed_for_user
    @blog_entries =
      BlogEntry.user_id_is(@user.id).
        visibility_is(BlogPreference::VISIBILITIES[:publiced]).
          descend_by_created_at.find(:all, :limit => 10)

    @xml_title = @user.preference.blog_preference.title
    @xml_link = index_for_user_user_blog_entries_path(:user_id => @user.id)
    respond_to do |type|
      type.rdf { render "feed.rdf.builder"}
      type.rss { render "feed.rxml" }
      type.atom { render "feed.atom.builder" }
    end
  end

  # ブログ情報表示
  def show
    @blog_entry = BlogEntry.find(params[:id])
    if current_user.try(:id) != @blog_entry.user_id
      @blog_entry.increment!(:access_count)
    end
    @user = @blog_entry.user
    @blog_comments = @blog_entry.blog_comments.paginate(paginate_options_for_comment)
  end

  # ブログ新規投稿画面表示
  def new
    @blog_entry = BlogEntry.new
    render_form
  end

  # ブログ編集画面表示
  def edit
    @blog_entry = BlogEntry.find(params[:id])
    render_form
  end

  # ブログ作成確認画面表示
  def confirm_before_create
    @blog_entry = BlogEntry.new(params[:blog_entry].merge(:user => current_user))
    return redirect_to new_blog_entry_path if params[:clear]

    # 住所検索
    if search_address_request_for_mobile?
      return render_form
    end

    if @blog_entry.valid?
      set_unpublic_image_uploader_keys(@blog_entry)
      render "confirm"
    else
      logger.debug{ "DEBUG(confirm_before_create) : #{@blog_entry.to_yaml}"}
      render_form
    end
  end

  # ブログ編集確認画面表示
  def confirm_before_update
    @blog_entry = BlogEntry.find(params[:id])
    @blog_entry.attributes = params[:blog_entry].merge(:user => current_user)
    return redirect_to edit_blog_entry_path(@blog_entry) if params[:clear]

    # 住所検索
    if search_address_request_for_mobile?
      return render_form
    end

    if @blog_entry.valid?
      set_unpublic_image_uploader_keys(@blog_entry)
      render "confirm"
    else
      logger.debug{ "DEBUG(confirm_before_update) : #{@blog_entry.to_yaml}"}
      render_form
    end
  end

  # レコード登録
  def create
    @blog_entry = BlogEntry.new(params[:blog_entry].merge(:user => current_user))
    return render_form if params[:cancel] || !@blog_entry.valid?

    ActiveRecord::Base.transaction do
      @blog_entry.save!
      # ブログ記事の所有者
      current_user.has_role!(:blog_entry_author, @blog_entry)
    end

    clear_unpublic_image_uploader_key
    redirect_to complete_after_create_blog_entry_path(@blog_entry)
  end

  # レコード更新
  def update
    @blog_entry = BlogEntry.find(params[:id])
    @blog_entry.attributes = params[:blog_entry].merge(:user => current_user)
    return render_form if params[:cancel] || !@blog_entry.valid?

    ActiveRecord::Base.transaction do
      @blog_entry.save!
    end

    clear_unpublic_image_uploader_key
    redirect_to complete_after_update_blog_entry_path(@blog_entry)
  end

  # レコード削除
  def destroy
    @blog_entry = BlogEntry.find(params[:id])
    ActiveRecord::Base.transaction do
      current_user.has_no_role!(:blog_entry_author, @blog_entry)
      @blog_entry.destroy
    end

    redirect_to index_for_user_user_blog_entries_path(:user_id => current_user.id)
  end

  # バックナンバ展開
  def spread_backnumber
    @backnumber_spread = true
    render :partial => "/share/blog_navigation_backnumber"
  end

  # クチコミマップを表示する
  def map
    @blog_entries = BlogEntry.by_activate_users.
                      blog_category_id_is(BlogCategory.wom_id).
                      latitude_not_null.longitude_not_null.zoom_not_null.descend_by_created_at
    @xml_title = "#{SnsConfig.title}クチコミマップ"
    @xml_link = map_blog_entries_url
    respond_to do |type|
      type.html do
        @blog_entries = @blog_entries.find(:all, :limit => 100)
      end
      type.rdf do
        @blog_entries = @blog_entries.find(:all, :limit => 20)
        render "feed.rdf.builder"
      end
      type.rss do
        @blog_entries = @blog_entries.find(:all, :limit => 20)
        render "feed.rxml"
      end
      type.atom do
        @blog_entries = @blog_entries.find(:all, :limit => 20)
        render "feed.atom.builder"
      end
    end
  end

  # ムービーマップ
  def index_for_map
    @blog_entries = BlogEntry.by_activate_users.
                      blog_category_id_is(BlogCategory.wom_id).
                      latitude_not_null.longitude_not_null.zoom_not_null.
                      paginate(paginate_options)
  end

  # ムービーマップ（携帯版）を表示する
  def map_for_mobile
    set_map_for_mobile_params
    @records =
      BlogEntry.by_activate_users.
        blog_category_id_is(BlogCategory.wom_id).
        by_latitude_range(@latitude_start, @latitude_end).
        by_longitude_range(@longitude_start, @longitude_end).
        paginate(paginate_options)
  end

  # 以前のユーザブログトップのURLでアクセスがあった場合に、現在のユーザのブログトップへリダイレクトする
  def relate_old_user_id_to_current
    raise ActiveRecord::RecordNotFound if params[:key].blank?
    raise ActiveRecord::RecordNotFound unless (user = User.find_by_old_id(params[:key]))
    redirect_to index_for_user_user_blog_entries_path(:user_id => user.id)
  end

  # 以前のブログのURLでアクセスがあった場合に、現在のブログへリダイレクトする
  def relate_old_blog_id_to_current
    raise ActiveRecord::RecordNotFound if params[:key].blank?
    raise ActiveRecord::RecordNotFound unless (blog_entry = BlogEntry.find_by_old_id(params[:key]))
    redirect_to blog_entry_path(blog_entry)
  end

  private

  # @blog_entry 設定
  def set_blog_entry
    @blog_entry = BlogEntry.find(params[:id])
  end

  # @user 設定
  def set_user
    if params.has_key?(:user_id)
      if params[:user_id].to_i == current_user.try(:id)
        @user = current_user
      else
        @user = User.find(params[:user_id])
      end
    elsif @blog_entry
      @user = @blog_entry.user
    elsif current_user
      @user = current_user
    end
  end

  # @title 設定
  def set_blog_title
    @title = @user.preference.blog_preference.title.dup
    if @blog_entry
      @title << " - #{@blog_entry.title}"
    end
  end

  # ファイルアップロードキー設定
  def set_unpublic_image_uploader_keys(entry)
    entry.blog_attachments.each do |at|
      self.unpublic_image_uploader_key = at.image_temp unless at.image_temp.blank?
    end
  end

  # 匿名ユーザは閲覧可能か？
  def anonymous_viewable?
    @blog_entry.anonymous_viewable?
  end

  # ログインユーザは閲覧可能か？
  def member_viewable?
    return true if @blog_entry.user_id == current_user.id
    @blog_entry.member_viewable? || firend_viewable?
  end

  # トモダチは閲覧可能か？
  def firend_viewable?
    current_user.friend_user?(@user) && @blog_entry.friend_viewable?
  end

  def paginate_options
    @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : BlogEntry.default_index_order),
      :include => [:user, :blog_category],
      :per_page => (params[:per_page] ? per_page_for_all : 10)
    }
    @paginate_options[:per_page] = 5 if request.mobile?
    return @paginate_options
  end

  def paginate_options_for_comment
    return @paginate_options_for_comment ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : BlogComment.default_index_order),
      :per_page => (request.mobile? ? 5 : BlogComment.count)
    }
  end

  def render_form
    @blog_entry.build_blog_attatchments
    @enable_tiny_mce = my_session[:enable_tiny_mce]
    render "form"
  end

  # カレンダー表示に必要なパラメータ設定
  def set_calendar_params
    @blog_entries_for_calender = params[:date] ? @blog_entries : @blog_entries.by_now_month
  end

  # ブログ記事検索
  def search_blog_entries
    @blog_entry = BlogEntry.new(:search_word => params[:keyword])
    unless @blog_entry.search_word.blank?
      @blog_entries = @blog_entries.title_or_body_like(@blog_entry.search_word)
    end
  end

  # 日付で絞り込み
  def scope_by_date
    if !params[:date].blank? && params[:date][:year] && params[:date][:month]
      if params[:date][:day].blank?
        date = Date.new(params[:date][:year].to_i, params[:date][:month].to_i, 1)
        @blog_entries = @blog_entries.
          created_at_greater_than_or_equal_to(date.to_time).
          created_at_less_than(date.next_month.to_time)
      else
        date = Date.new(params[:date][:year].to_i, params[:date][:month].to_i, params[:date][:day].to_i)
        @blog_entries = @blog_entries.
          created_at_greater_than_or_equal_to(date.to_time).
          created_at_less_than(date.next.to_time)
        @calendar_day = date.day
      end

      @calendar_year = date.year
      @calendar_month = date.month
    end
  end

  # カテゴリで絞り込み
  def scope_by_category
    if params[:blog_category_id]
      @blog_category = BlogCategory.find(params[:blog_category_id])
      @blog_entries = @blog_entries.blog_category_id_is(@blog_category.id)
    end
  end

  # 対象ユーザのブログを閲覧できるかチェック
  def check_viewable_user_filter
    case
    when displayed_user.same_user?(current_user) || @user.preference.blog_preference.anonymous_viewable?
      return true
    when !logged_in? && !@user.preference.blog_preference.anonymous_viewable?
      raise Mars::AccessDenied
    when current_user &&
        (!current_user.friend_user?(@user) &&
         @user.preference.blog_preference.friend_viewable?)
      redirect_to not_friend_error_blog_entries_path
      return false
    end
  end


  # ブログ記事を閲覧できるかチェック
  def check_viewable_entry_filter
    case
    when anonymous_viewable?
      return true
    when !logged_in? && !anonymous_viewable?
      raise Mars::AccessDenied
    when current_user && !member_viewable?
      redirect_to not_friend_error_blog_entries_path
      return false
    end
  end

  # 全件指定(0)の場合は外部RSSを含むブログエントリ数を返す
  def per_page_for_all
    if all_pages?
      @blog_entries.size
    else
      params[:per_page]
    end
  end
end

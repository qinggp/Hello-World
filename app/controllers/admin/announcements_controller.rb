# お知らせ管理
class Admin::AnnouncementsController < Admin::ApplicationController

  #お知らせ一覧表示時の1ページあたりのデフォルト表示件数
  DEFAULT_PER_PAGE = 5

  with_options :redirect_to => :admin_announcements_url do |con|
    con.verify :params => "id", :only => %w(confirm_before_update)
    con.verify :params => "information",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    #全件表示チェック
    #
    #全件表示    @paginated == false
    #件数指定表示 @paginated == true
    if params[:per_page_important] && params[:per_page_important].to_i == 0
      @paginated_important = false
    else
      @paginated_important = true
    end

    if params[:per_page_new] && params[:per_page_new].to_i == 0
      @paginated_new = false
    else
      @paginated_new = true
    end

    
    #重要
    if @paginated_important
      @announcements_important = Information.paginate(paginate_options_for_announcements(Information::DISPLAY_TYPES[:important],nil))
    else
      @announcements_important = Information.find(:all,:conditions => ["display_type = ?", Information::DISPLAY_TYPES[:important]],
                                                  :order => (params[:order_important] ? construct_sort_order_for_announcements(:order => :order_important,:order_modifier => :order_modifier_important) : Information.default_index_order))
    end
    
    #最新・非公開
    if @paginated_new
      @announcements_new = Information.paginate(paginate_options_for_announcements(Information::DISPLAY_TYPES[:new], Information::DISPLAY_TYPES[:private]))
    else
      @announcements_new = Information.find(:all,:conditions => ["display_type = ? OR display_type = ?", Information::DISPLAY_TYPES[:new], Information::DISPLAY_TYPES[:private]],
                                            :order => (params[:order_new] ? construct_sort_order_for_announcements(:order => :order_new,:order_modifier => :order_modifier_new) : Information.default_index_order))
    end
    
    #固定 
      order = !params[:order_fixed].blank? ? sanitize_sql(params[:order_fixed]) : "information.created_at"
      order_modifier = params[:order_modifier_fixed] ? sanitize_sql(params[:order_modifier_fixed]) : "DESC"
      @announcements_fixed = Information.find(:all,:conditions => ["display_type = ?", Information::DISPLAY_TYPES[:fixed]],:order => "#{order} #{order_modifier}")
  end

  # 登録フォームの表示．
  def new
    @announcement ||= Information.new
    render "form"
  end

  # 編集フォームの表示．
  def edit
    @announcement ||= Information.find(params[:id])
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @announcement = Information.new(params[:information])
    return redirect_to new_admin_announcement_path if params[:clear]

    #エラー判定項目
    # 1. タイトル、本文の入力チェック
    # 2. 表示期間の入力形式チェック


    if @announcement.valid?     
      render "confirm"
    else
      render "form"
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @announcement = Information.find(params[:id])
    @announcement.attributes = params[:information]
    return redirect_to edit_admin_announcement_path(@announcement) if params[:clear]

    if @announcement.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 登録データをDBに保存．
  def create
    @announcement = Information.new(params[:information])
    return render "form" if params[:cancel] || !@announcement.valid?
    Information.transaction do
        @announcement.save!
    end

    redirect_to complete_after_create_admin_announcement_path(@announcement)
  end

  # 更新データをDBに保存．
  def update
    @announcement = Information.find(params[:id])
    @announcement.attributes = params[:information]
    return render "form" if params[:cancel] || !@announcement.valid?

    Information.transaction do
      @announcement.save!
    end

    redirect_to complete_after_update_admin_announcement_path(@announcement)
  end

  private
  # 一覧表示オプション
  def paginate_options_for_announcements(num_a = nil,num_b = nil)
    #表示種別重要
    if num_a == Information::DISPLAY_TYPES[:important]
        conditions = "display_type = #{num_a}"
        return paginate_options ||= {
          :page => (params[:select_page_important] ? sanitize_sql(params[:select_page_important]) : nil ),
          :order => (params[:order_important] ? construct_sort_order_for_announcements(:order => :order_important,:order_modifier => :order_modifier_important) : Information.default_index_order),
          :conditions => (!num_a.nil? ? conditions : ''),
          :per_page => (params[:per_page_important] ? sanitize_sql(params[:per_page_important]) : DEFAULT_PER_PAGE)
        }
    #表示種別最新・表示種別非公開
    elsif num_a == Information::DISPLAY_TYPES[:new] && num_b == Information::DISPLAY_TYPES[:private]
      conditions = "display_type in (#{num_a},#{num_b})"
      return paginate_options ||= {
          :page => (params[:select_page_new] ? sanitize_sql(params[:select_page_new]) : nil ),
          :order => (params[:order_new] ? construct_sort_order_for_announcements(:order => :order_new,:order_modifier => :order_modifier_new) : Information.default_index_order),
          :conditions => (!num_a.nil? ? conditions : ''),
          :per_page => (params[:per_page_new] ? sanitize_sql(params[:per_page_new]) : DEFAULT_PER_PAGE)
      }
    end
  end

  # SQLオーダ句作成
  #
  # ==== 備考
  #
  # ソート時に使用する
  def construct_sort_order_for_announcements(option ={})
    return params[option[:order_modifier]].blank? ? sanitize_sql(params[option[:order]]) :
      sanitize_sql("#{params[option[:order]]} #{params[option[:order_modifier]]}")
  end
  
end

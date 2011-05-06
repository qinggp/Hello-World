# バナー管理
class Admin::BannersController < Admin::ApplicationController

  include Mars::UnpublicImageAccessible

  unpublic_image_accessible :model_name => :banner
  # 昇順降順を表す定数
  ASC = 1
  DESC = 2

  # ソート対象を表す定数
  CREATED_AT = 1
  CLICK_COUNT = 2
  EXPIRE_DATE = 3

  with_options :redirect_to => :admin_banners_url do |con|
    con.verify :params => "id", :only => %w(destroy confirm_before_update)
    con.verify :params => "banner",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    if params[:per_page] && params[:per_page].to_i == 0
      @paginated = false
    else
      @paginated = true
    end
    order = construct_order_by_query
    if @paginated
      @banners =
        Banner.paginate(:per_page => (params[:per_page] ? params[:per_page] : 5),
                        :page => params[:page],
                        :order => order)
    else
      @banners = Banner.find(:all,:order => order)
    end
  end

  # 登録フォームの表示．
  def new
    if params[:banner]
      params[:banner].delete(:image_temp)
      @banner = Banner.new(params[:banner])
    else
      @banner = Banner.new
    end
    render "form"
  end

  # 編集フォームの表示．
  def edit
    @banner = Banner.find(params[:id])
    if params[:banner]
      params[:banner].delete(:image_temp)
      @banner.attributes = params[:banner]
    end
    unless @banner.expire_date
      @not_set_expire = true
    end
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @banner = Banner.new(params[:banner])
    if params[:not_set_expire]
      @banner.expire_date = nil
    end
    return redirect_to new_admin_banner_path if params[:clear]

    if @banner.valid?
      set_unpublic_image_uploader_keys(@banner)
      render "confirm"
    else
      render "form"
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @banner = Banner.find(params[:id])
    @banner.attributes = params[:banner]
    if params[:not_set_expire]
      @banner.expire_date = nil
    end
    return redirect_to edit_admin_banner_path(@banner) if params[:clear]

    if @banner.valid?
      set_unpublic_image_uploader_keys(@banner)
      render "confirm"
    else
      render "form"
    end
  end

  # 登録データをDBに保存．
  def create
    @banner = Banner.new(params[:banner])
    return new if params[:cancel] || !@banner.valid?

    Banner.transaction do
      @banner.save!
    end

    redirect_to complete_after_create_admin_banner_path(@banner)
  end

  # 更新データをDBに保存．
  def update
    @banner = Banner.find(params[:id])
    @banner.attributes = params[:banner]
    return edit if params[:cancel] || !@banner.valid?

    Banner.transaction do
      @banner.save!
    end

    redirect_to complete_after_update_admin_banner_path(@banner)
  end

  # レコードの削除
  def destroy
    @banner = Banner.find(params[:id])
    @banner.destroy

    redirect_to admin_banners_url
  end

  private

  #クエリのorder句の生成
  def construct_order_by_query
    order_by_query = ""

    if params[:order] && params[:order][:kind]
      order_by_query =
        case params[:order][:kind].to_i
        when CREATED_AT
          "created_at"
        when CLICK_COUNT
          "click_count"
        when EXPIRE_DATE
          "expire_date"
        else
          "created_at"
        end
    else
      order_by_query = "created_at desc"
    end

    if params[:order] && params[:order][:asc_or_desc]
      if params[:order][:asc_or_desc].to_i == DESC
        order_by_query << " desc "
      end
    end

    order_by_query
  end

  # ファイルアップロードキー設定
  def set_unpublic_image_uploader_keys(banner)
    self.unpublic_image_uploader_key = banner.image_temp unless banner.image_temp.blank?
  end



end

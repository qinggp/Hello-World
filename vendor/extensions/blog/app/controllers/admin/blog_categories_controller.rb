# ブログカテゴリ管理
class Admin::BlogCategoriesController < Admin::ApplicationController

  DEFAULT_PER_PAGE = 5

  with_options :redirect_to => :admin_blog_categories_url do |con|
    con.verify :params => "id", :only => %w(confirm_before_update)
    con.verify :params => "blog_category", 
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    if params[:per_page] && params[:per_page].to_i == 0
      @paginated = false
    else
      @paginated = true
    end
    if @paginated
      option = paginate_options
      if params[:order] == 'users.name'
        option.merge!(:include => 'user')
      end
      @blog_categories = BlogCategory.paginate(option)
    else
      option = {:order => (params[:order] ? construct_sort_order : BlogCategory.default_index_order)}
      if params[:order] == 'users.name'
        option.merge!(:include => 'user')
      end
      @blog_categories = BlogCategory.find(:all, option)
    end
  end

  # 登録フォームの表示．
  def new
    @blog_category = BlogCategory.new
    render "form"
  end

  # 編集フォームの表示．
  def edit
    @blog_category ||= BlogCategory.find(params[:id])
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @blog_category = BlogCategory.new(params[:blog_category])
    return redirect_to new_admin_blog_category_path() if params[:clear]

    if @blog_category.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @blog_category = BlogCategory.find(params[:id])
    @blog_category.attributes = params[:blog_category]
    return redirect_to edit_admin_blog_category_path(@blog_category) if params[:clear]

    if @blog_category.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 登録データをDBに保存．
  def create
    @blog_category = BlogCategory.new(params[:blog_category])
    return render "form" if params[:cancel] || !@blog_category.valid?

    @blog_category.shared = true
    BlogCategory.transaction do
      @blog_category.save!
    end

    redirect_to complete_after_create_admin_blog_category_path(@blog_category)
  end

  # 更新データをDBに保存．
  def update
    @blog_category = BlogCategory.find(params[:id])
    @blog_category.attributes = params[:blog_category]
    return render "form" if params[:cancel] || !@blog_category.valid?

    BlogCategory.transaction do
      @blog_category.save!
    end

    redirect_to  complete_after_update_admin_blog_category_path(@blog_category)
  end

  private
  #一覧表示オプション
  def paginate_options
    @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : BlogCategory.default_index_order),
      :per_page => (params[:per_page] ? sanitize_sql(params[:per_page]) : DEFAULT_PER_PAGE)
    }
    return @paginate_options
  end

  def set_user
    @user = current_user
  end

  def render_form
    @blog_categories = BlogCategory.user_id_is(nil).find(:all, order_options)
    render "form"
  end
end

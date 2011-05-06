# ブログカテゴリ管理
class BlogCategoriesController < ApplicationController
  with_options :redirect_to => :blog_categories_url do |con|
    con.verify :params => "id", :only => %w(destroy confirm_before_update)
    con.verify :params => "blog_category",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  access_control do
    allow logged_in
  end

  # レコードの詳細情報の表示．
  def show
    @blog_category = BlogCategory.find(params[:id])
  end

  # 登録フォームの表示．
  def new
    @blog_category = BlogCategory.new
    render_form
  end

  # 編集フォームの表示．
  def edit
    @blog_category = current_user.blog_categories.find(params[:id])
    render_form
  end

  # 登録確認画面表示
  def confirm_before_create
    @blog_category = BlogCategory.new(params[:blog_category])
    return redirect_to new_user_blog_category_path(current_user) if params[:clear]

    if @blog_category.valid?
      render "confirm"
    else
      render_form
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @blog_category = BlogCategory.find(params[:id])
    @blog_category.attributes = params[:blog_category]
    return redirect_to edit_user_blog_category_path(current_user, @blog_category) if params[:clear]

    if @blog_category.valid?
      render "confirm"
    else
      render_form
    end
  end

  # 登録データをDBに保存．
  def create
    @blog_category = BlogCategory.new(params[:blog_category])
    @blog_category.user = current_user
    if params[:cancel] || !@blog_category.valid?
      return render_form
    end

    BlogCategory.transaction do
      @blog_category.save!
    end

    redirect_to complete_after_create_user_blog_category_path(current_user, @blog_category)
  end

  # 更新データをDBに保存．
  def update
    @blog_category = current_user.blog_categories.find(params[:id])
    @blog_category.attributes = params[:blog_category]
    @blog_category.user = current_user
    if params[:cancel] || !@blog_category.valid?
      return render_form
    end

    BlogCategory.transaction do
      @blog_category.save!
    end

    redirect_to complete_after_update_user_blog_category_path(current_user, @blog_category)
  end

  # レコードの削除
  def destroy
    @blog_category = current_user.blog_categories.find(params[:id])
    @blog_category.destroy

    redirect_to new_user_blog_category_path(current_user)
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    logged_in? ? index_for_user_user_blog_entries_path(:user_id => current_user) : search_blog_entries_path
  end

  private
  # 一覧表示オプション
  def order_options
    return @order_options ||= {
      :order => (params[:order] ? construct_sort_order : BlogCategory.default_index_order),
    }
  end

  def paginate_options_for_mobile
    return @paginate_options_for_mobile ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : BlogCategory.default_index_order),
      :per_page => (request.mobile? ? 5 : 10)
    }
  end

  def set_user
    @user = current_user
  end

  def render_form
    @blog_categories = BlogCategory.user_id_is(current_user.id)
    if request.mobile?
      @blog_categories = @blog_categories.paginate(paginate_options_for_mobile)
    else
      @blog_categories = @blog_categories.find(:all, order_options)
    end
    render "form"
  end
end

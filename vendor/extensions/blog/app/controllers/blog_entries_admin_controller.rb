# ブログ管理
class BlogEntriesAdminController < ApplicationController
  before_filter :set_user
  before_filter :action_routing, :only => %w(index search)

  access_control do
    allow logged_in, :if => :current_user_blog?
  end

  # ブログ管理画面表示
  #
  # ==== 備考
  # ボタン名によって update_checked, destroy_checked アクション等にリダイ
  # レクトします。
  def index
    @title = "ブログ管理"
    search_refinement
    render :index
  end
  alias :search :index

  # ブログ記事属性一括修正
  def update_checked
    change_values = {}
    params[:blog_entry].map{|k, v| change_values[k] = v unless v.blank?}

    BlogEntry.transaction do
      unless params[:checked_ids].blank? || change_values.blank?
        BlogEntry.update_all(change_values, ["id in (?)", params[:checked_ids]])
      end
    end

    redirect_to user_blog_entries_admin_index_path(@user)
  end

  # ブログ記事属性一括削除
  def destroy_checked
    BlogEntry.transaction do
      unless params[:checked_ids].blank?
        BlogEntry.destroy_all(["id in (?)", params[:checked_ids]])
      end
    end

    redirect_to user_blog_entries_admin_index_path(@user)
  end

  # ブログ記事の全チェクボックスにチェックする
  def all_checked
    search_refinement
    params[:checked_ids] = @blog_entries.map(&:id)
    render :index
  end

  # ブログ記事一括削除確認画面
  def confirm_before_destroy_checked
    @blog_entry = BlogEntry.new(params[:blog_entry])
    params[:checked_ids] ||= []
  end
  alias :confirm_before_update_checked :confirm_before_destroy_checked

  private

  def action_routing
    case
    when params.has_key?(:all_checked)
      redirect_to all_checked_user_blog_entries_admin_path(@user, :blog_entry => params[:blog_entry])
    when params.has_key?(:all_unchecked)
      redirect_to user_blog_entries_admin_index_path(@user, :blog_entry => params[:blog_entry])
    when params.has_key?(:update_checked)
      if request.mobile?
        redirect_to confirm_before_update_checked_user_blog_entries_admin_path(@user,
                      :blog_entry => params[:blog_entry],
                      :checked_ids => params[:checked_ids])
      else
        redirect_to update_checked_user_blog_entries_admin_path(@user,
                      :blog_entry => params[:blog_entry],
                      :checked_ids => params[:checked_ids])
      end
    when params.has_key?(:destroy_checked)
      if request.mobile?
        redirect_to confirm_before_destroy_checked_user_blog_entries_admin_path(@user,
                      :blog_entry => params[:blog_entry],
                      :checked_ids => params[:checked_ids])
      else
        redirect_to destroy_checked_user_blog_entries_admin_path(@user,
                      :blog_entry => params[:blog_entry],
                      :checked_ids => params[:checked_ids])
      end
    else
      return true
    end
    return false
  end

  def set_user
    @user = User.find(params[:user_id])
  end

  def current_user_blog?
    current_user.id == @user.id
  end

  def paginate_options
    @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : BlogEntry.default_index_order),
      :include => [:user, :blog_category],
      :per_page => (params[:per_page] ? per_page_for_all(BlogEntry) : 10)
    }
    @paginate_options[:per_page] = 5 if request.mobile?
    return @paginate_options
  end

  # 条件による絞り込み検索
  def search_refinement
    @blog_entry = BlogEntry.new(params[:blog_entry])
    res = BlogEntry.by_user(@user)
    res = res.visibility_is(@blog_entry.visibility) if @blog_entry.visibility
    res = res.comment_restraint_is(@blog_entry.comment_restraint) if @blog_entry.comment_restraint
    res = res.blog_category_id_is(@blog_entry.blog_category_id) if @blog_entry.blog_category_id
    @blog_entries = res.paginate(paginate_options)
  end
end

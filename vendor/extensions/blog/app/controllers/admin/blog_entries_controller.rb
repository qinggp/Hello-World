# ブログ管理
class Admin::BlogEntriesController < Admin::ApplicationController

  with_options :redirect_to => :admin_blog_entries_url do |con|
    con.verify :params => "id", :only => %w(admin_blog_attachment_destroy)
    con.verify :params => "type",
      :only => %w(wrote_administration_blog_entries)
    con.verify :method => :delete, :only => %w(admin_blog_attachment_destroy)
  end

  # ブログの書き込み管理
  def wrote_administration_blog_entries
    if params[:per_page] && params[:per_page].to_i == 0
      @paginated = false
    else
      @paginated = true
    end

    conditions = []
    if params[:search_id] && params[:search_id] != ''
          @search_id = params[:search_id]
          conditions = ['id = ?']
          conditions.push(params[:search_id].to_i)
    end
    case params[:type]
    when "write"
      if @paginated
        @blog_entries = BlogEntry.paginate(
                          :conditions => conditions,
                          :per_page => (params[:per_page] ? params[:per_page] : 5),
                          :page => params[:page],
                          :order => 'id desc')
      else
        @blog_entries = BlogEntry.all
      end
      render "wrote_administration_blog_entries_write"
    when  "file"
      if @paginated
        @blog_attachments = BlogAttachment.paginate(
                              :conditions => conditions,
                              :per_page => (params[:per_page] ? params[:per_page] : 10),
                              :page => params[:page],
                              :order => 'updated_at desc')
      else
        @blog_attatiments = BlogAttachment.all
      end
      render "wrote_administration_blog_entries_file"
    end
  end

    # ブログコメントの書き込み管理
  def wrote_administration_blog_comments
    if params[:per_page] && params[:per_page].to_i == 0
      @paginated = false
    else
      @paginated = true
    end

    conditions = []
    if @paginated
      if params[:search_id] && params[:search_id] != ''
        @search_id = params[:search_id]
        conditions = ['blog_entry_id = ?']
        conditions.push(params[:search_id].to_i)
      end

      @blog_comments = BlogComment.paginate(
                         :conditions => conditions,
                         :per_page => (params[:per_page] ? params[:per_page] : 5),
                         :page => params[:page],
                         :order => 'id asc')
    else
      @blog_comments = BlogComment.all
    end

    render "wrote_administration_blog_comments_write"
  end

  def admin_blog_attachment_destroy
    unless BlogAttachment.find(params[:id]).destroy
      flash[:error] = "削除失敗しました。"
    end
    redirect_to :action => :wrote_administration_blog_entries, :type => "file"
  end

  
  private
  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : BlogEntry.default_index_order),
    }
  end
end

# <%= controller_class_name -%>管理
#
# FIXME: 説明
class <%= controller_class_name -%>Controller < <%= controller_class_nesting_with_colon -%>ApplicationController

  with_options :redirect_to => :<%= plural_name_with_nesting %>_url do |con|
    con.verify :params => "id", :only => %w(show destroy confirm_before_update)
    con.verify :params => "<%= file_name %>", 
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    @<%= table_name %> = <%= class_name %>.paginate(:all, paginate_options)
  end

  # レコードの詳細情報の表示．
  def show
    @<%= file_name %> = <%= class_name %>.find(params[:id])
  end

  # 登録フォームの表示．
  def new
    @<%= file_name %> = <%= class_name %>.new
    render "form"
  end

  # 編集フォームの表示．
  def edit
    @<%= file_name %> = <%= class_name %>.find(params[:id])
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @<%= file_name %> = <%= class_name %>.new(params[:<%= file_name %>])
    return redirect_to new_<%= file_name %>_path if params[:clear]

    if @<%= file_name %>.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @<%= file_name %> = <%= class_name %>.find(params[:id])
    @<%= file_name %>.attributes = params[:<%= file_name %>]
    return redirect_to edit_<%= file_name %>_path(@<%= file_name %>) if params[:clear]

    if @<%= file_name %>.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 登録データをDBに保存．
  def create
    @<%= file_name %> = <%= class_name %>.new(params[:<%= file_name %>])
    return render "form" if params[:cancel] || !@<%= file_name %>.valid?

    <%= class_name %>.transaction do
      @<%= file_name %>.save!
    end

    redirect_to complete_after_create_<%= file_name %>_path(@<%= file_name %>)
  end

  # 更新データをDBに保存．
  def update
    @<%= file_name %> = <%= class_name %>.find(params[:id])
    @<%= file_name %>.attributes = params[:<%= file_name %>]
    return render "form" if params[:cancel] || !@<%= file_name %>.valid?

    <%= class_name %>.transaction do
      @<%= file_name %>.save!
    end

    redirect_to complete_after_update_<%= file_name %>_path(@<%= file_name %>)
  end

  # レコードの削除
  def destroy
    @<%= file_name %> = <%= class_name %>.find(params[:id])
    @<%= file_name %>.destroy

    redirect_to <%= plural_name_with_nesting %>_url
  end

  private
  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : <%= class_name %>.default_index_order),
    }
  end
end

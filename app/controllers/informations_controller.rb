# お知らせ機能
class InformationsController < ApplicationController
  with_options :redirect_to => :infromations_url do |con|
    con.verify :params => "id", :only => %w(show)
  end

  # お知らせ一覧
  def index
    @informations =
      Information.by_viewable_for_user(current_user).paginate(paginate_options)
  end

  # 重要なお知らせ一覧
  def index_for_important
    @informations =
      Information.by_viewable_for_user(current_user).by_not_expire.
        display_type_is(Information::DISPLAY_TYPES[:important]).paginate(paginate_options)
    render "index"
  end

  # お知らせ詳細表示
  def show
    @information =
      Information.by_viewable_for_user(current_user).find_by_id(params[:id])

    redirect_to informations_path if @information.nil?
  end

  private
  # 一覧表示オプション
  def paginate_options
    @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : Information.default_index_order),
      :per_page => (params[:per_page] ? per_page_for_all(Information) : 20)
    }
    @paginate_options[:per_page] = 10 if request.mobile?
    return @paginate_options
  end
end

# お気に入り管理
#
# ユーザのお気に入りURLを管理します。
class FavoritesController < ApplicationController
  before_filter :set_favorite, :only => %w(show edit confirm_before_update update destroy)

  with_options :redirect_to => :favorites_url do |con|
    con.verify :params => "id", :only => %w(show destroy confirm_before_update)
    con.verify :params => "favorite",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  access_control do
    owner_actions = %w(show edit confirm_before_update update destroy)
    allow logged_in, :except => owner_actions
    allow logged_in, :to => owner_actions, :if => :favorite_owner?
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    @favorites = Favorite.user_id_is(current_user.id).paginate(paginate_options)
  end

  # レコードの詳細情報の表示．
  def show
    @favorite = Favorite.find(params[:id])
  end

  # 編集フォームの表示．
  def edit
    @favorite = Favorite.find(params[:id])
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @favorite = Favorite.new(params[:favorite])

    if @favorite.valid?
      render "confirm"
    else
      redirect_to favorites_path
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @favorite = Favorite.find(params[:id])
    @favorite.attributes = params[:favorite]
    return redirect_to edit_favorite_path(@favorite) if params[:clear]

    if @favorite.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 登録データをDBに保存．
  def create
    @favorite = Favorite.new(params[:favorite])
    @favorite.user = current_user
    return redirect_to favorites_path unless @favorite.valid?
    return redirect_to @favorite.url if params[:cancel]

    Favorite.transaction do
      @favorite.save!
    end

    redirect_to @favorite.url
  end

  # 更新データをDBに保存．
  def update
    @favorite = Favorite.find(params[:id])
    @favorite.attributes = params[:favorite]
    return render "form" if params[:cancel] || !@favorite.valid?

    Favorite.transaction do
      @favorite.save!
    end

    redirect_to complete_after_update_favorite_path(@favorite)
  end

  # レコードの削除
  def destroy
    @favorite = Favorite.find(params[:id])
    @favorite.destroy
    redirect_to params[:back_url] || favorites_path
  end

  # 選択レコードの一括削除
  def destroy_checked
    Favorite.transaction do
      unless params[:checked_ids].blank?
        Favorite.destroy_all(["id in (?) AND user_id = ?", params[:checked_ids], current_user.id])
      end
    end

    redirect_to favorites_path
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    favorites_path
  end

  private
  # 一覧表示オプション
  def paginate_options
    @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : Favorite.default_index_order),
      :per_page => (params[:per_page] ? per_page_for_all(Favorite) : 20)
    }
    @paginate_options[:per_page] = 10 if request.mobile?
    return @paginate_options
  end

  def set_favorite
    @favorite = Favorite.find_by_id(params[:id])
  end

  def favorite_owner?
    @favorite.owner?(current_user)
  end
end

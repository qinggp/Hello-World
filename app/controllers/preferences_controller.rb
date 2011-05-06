# ユーザ設定管理
#
# ユーザ個人の設定を管理するコントローラ
class PreferencesController < ApplicationController

  with_options :redirect_to => :preferences_url do |con|
    con.verify :params => "id", :only => %w(show destroy confirm_before_update)
    con.verify :params => "preference",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  access_control do
    allow logged_in
  end

  before_filter :valid_preference_id, :only => %w(edit confirm_before_update update)

  # 登録フォームの表示．
  def new
    @preference = Preference.new
    render "form"
  end

  # 編集フォームの表示．
  def edit
    @preference = Preference.find(params[:id])
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @preference = Preference.new(params[:preference])
    return redirect_to new_preference_path if params[:clear]

    if @preference.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @preference = Preference.find(params[:id])
    @preference.attributes = params[:preference]
    return redirect_to edit_preference_path(@preference) if params[:clear]

    if @preference.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 登録データをDBに保存．
  def create
    @preference = Preference.new(params[:preference])
    return render "form" if params[:cancel] || !@preference.valid?

    Preference.transaction do
      @preference.save!
    end

    redirect_to complete_after_create_preference_path(@preference)
  end

  # 更新データをDBに保存．
  def update
    @preference = Preference.find(params[:id])
    @preference.attributes = params[:preference]
    return render "form" if params[:cancel] || !@preference.valid?

    Preference.transaction do
      @preference.save!
    end

    redirect_to complete_after_update_preference_path(@preference)
  end

  # ホームレイアウトの更新
  def update_home_layout_type
    @preference = current_user.preference
    @preference.home_layout_type = params[:preference][:home_layout_type]
    @preference.save!
    redirect_to my_home_users_path
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    logged_in? ? edit_preference_path(:id => current_user.preference) : root_path
  end

  private

  # 正しいユーザの設定であるか？
  def valid_preference_id
    return true if current_user.preference.id == params[:id].to_i
    raise Mars::AccessDenied
  end
end

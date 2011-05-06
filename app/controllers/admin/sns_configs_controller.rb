# SNS設定管理
class Admin::SnsConfigsController < Admin::ApplicationController
  include Mars::GmapSelectable::PC

  with_options :redirect_to => :admin_sns_configs_url do |con|
    con.verify :params => "id", :only => %w(confirm_before_update)
    con.verify :params => "sns_config", 
      :only => %w(confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_update)
    con.verify :method => :put, :only => %w(update)
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index    
    @sns_config ||= SnsConfig.find(:first)
    redirect_to edit_admin_sns_config_path(@sns_config.id)
  end

  # 編集フォームの表示．
  def edit
    @sns_config ||= SnsConfig.find(params[:id])
    render "form"
  end

  # 編集確認画面表示
  def confirm_before_update
    @sns_config = SnsConfig.find(params[:id])
    @sns_config.attributes = params[:sns_config]
    return redirect_to edit_admin_sns_config_path(@sns_config) if params[:clear]
    if params[:clear_coordinates]
      @sns_config.maps_longitude,@sns_config.maps_latitude,@sns_config.maps_zoom = nil,nil,nil
      return render "form"
    end
    if @sns_config.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 更新データをDBに保存．
  def update
    @sns_config = SnsConfig.find(params[:id])
    @sns_config.attributes = params[:sns_config]
    return render "form" if params[:cancel] || !@sns_config.valid?

    SnsConfig.transaction do
      @sns_config.save!
    end

    redirect_to complete_after_update_admin_sns_config_path(@sns_config)
  end

  private
  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : SnsConfig.default_index_order),
    }
  end
end

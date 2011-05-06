# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  mobile_filter
  trans_sid

  # helper :all
  include AuthenticatedSystem

  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  filter_parameter_logging :password

  # 未承認ユーザのアクセスをチェック
  before_filter :deactive_check

  theme SnsConfig.master_record.try(:sns_theme).try(:name)

  # レコード作成完了画面表示
  def complete_after_create
    @message = "作成完了いたしました。"
    render "/share/complete", :layout => "application"
  end

  # レコード更新完了画面表示
  def complete_after_update
    @message = "修正完了いたしました。"
    render "/share/complete", :layout => "application"
  end

  # レコード削除完了画面表示
  def complete_after_destroy
    @message = "削除完了いたしました。"
    render "/share/complete", :layout => "application"
  end

  # レコード削除確認画面（携帯のみ使用）
  def confirm_before_destroy
    render "confirm_before_destroy_mobile", :layout => "application"
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    logged_in? ? my_home_users_path : root_path
  end
  hide_action :contents_home_path

  protected

  # 現在表示中のユーザ取得
  def displayed_user
    @display_user ||= @user
    unless params[:user_id].blank?
      @display_user ||= User.find_by_id(params[:user_id])
    end
    return @display_user
  end
  helper_method :displayed_user

  private

  # コントローラ名で名前空間を区切ったセッション情報
  #
  # ==== 備考
  #
  # 素でsessionを使うと名前がぶつかる恐れがあるため定義
  def my_session
    session[params[:controller]] ||= {}
    return session[params[:controller]]
  end

  # 携帯用のアクションにfilterをかけ、携帯からのアクセスでなければ
  # トップページへ飛ばすようにする
  def mobile_only
    redirect_to('/') unless request.mobile?
  end

  # SQLのサニタイズをコントローラで使えるようにする
  def sanitize_sql(sql)
    # NOTE: ActiveRecord::Baseから呼び出せなくなっている
    User.__send__(:sanitize_sql_for_conditions, sql).untaint
  end

  # SQLオーダ句作成
  #
  # ==== 備考
  #
  # ソート時に使用する
  def construct_sort_order
    return params[:order_modifier].blank? ? sanitize_sql(params[:order]) :
      sanitize_sql("#{params[:order]} #{params[:order_modifier]}")
  end

  # ページネーション無しで全件表示するかどうか
  def all_pages?
    params[:per_page] && params[:per_page].to_i == Mars::ALL_PAGES
  end

  # 全件指定(0)の場合は model_klass のレコード数を返す
  def per_page_for_all(model_klass)
    all_pages? ? model_klass.count : params[:per_page]
  end

  # 実環境での例外ハンドリング
  #
  # ==== 備考
  #
  # localhostや127.0.0.1以外からのアクセスで起動します。
  def rescue_action_in_public(exception)
    case exception
    when ActiveRecord::RecordNotFound
      flash[:error] = ("不正なURLです。").untaint
    when Acl9::AccessDenied, Mars::AccessDenied
      # 特に何も表示しない
    else
      flash[:error] = ("予期せぬエラーが発生しました。" +
                       @template.link_to("お問い合わせフォーム", new_ask_path) +
                       "からお問い合わせください。").untaint
      logger.error{ "ERROR: #{exception.class} : #{exception.message}" }
    end
    redirect_to root_url
  end

  # X-SENDFILE でファイルを送信
  def x_send_file(filename, options={})
    send_file(filename, options.merge(:x_sendfile => true))
  end

  # 送信元IPで、スパムかどうか判定する
  # ただし、ログインしている場合は判定はスルー
  def check_spam_ip_address
    return true if logged_in? || !SpamIpAddress.find_by_ip_address(request.remote_ip)
    logger.info "#{request.remote_ip} is spam judgement"
    return  render :file => "#{RAILS_ROOT}/public/404.html", :status => 404, :layout => false
  end
end

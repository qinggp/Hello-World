require 'fileutils'

class MoviesController < ApplicationController
  include Mars::CalendarViewable
  include Mars::GmapSelectable::PC
  include Mars::GmapSelectable::Mobile
  include Mars::GmapViewable::Mobile

  # 認証エラー時にリダイレクトされる転送先
  #TOP_URL = 'http://matsuesns.jp'
  TOP_URL = Mars::Movie::ResourceLoader['application']['top_url']

  # アップロードファイルの最大サイズ(byte)
  UPLOADED_FILE_MAX_SIZE = Movie::MAX_SIZE_OF_MOVIE_FILE

  # 許可拡張子
  ALLOWED_EXTENSIONS = Movie::ALLOWED_EXTENSIONS

  before_filter :set_current_user

  access_control do
    logged_in_actions = %w(new create_confirm create create_complete
                           edit update_confirm update update_complete index_for_user
                           delete delete_complete update_my_movies)
    allow all, :except => logged_in_actions
    allow logged_in, :to => logged_in_actions
  end

  # ムービー個人ポータルページ表示
  def index
    user_id = @user.try(:id)
    @title = 'ムービーホーム'
    @todays_movies = Movie.by_activate_users.todays(user_id)
    @recent_movies = Movie.by_activate_users.recents_paginate(user_id, paginate_options)
    @movies = @user.movies.by_activate_users.paginate(paginate_options) if @user
    set_calendar_params
  end

  # 新着ムービー一覧（携帯用）
  def index_for_recent
    @title = '新着ムービー'
    @movies = Movie.by_activate_users.recents_paginate(@user.try(:id), paginate_options)
    render "index_for_recent_mobile"
  end

  # マイムービー一覧（携帯用）
  def index_for_user
    @title = 'マイムービー一覧'
    @user = User.find(params[:user_id])
    @movies = @user.movies.by_activate_users.paginate(paginate_options)
    render "index_for_user_mobile"
  end

  # ムービー再生画面表示
  def show
    @title = 'ムービー再生'
    user_id = @user.try(:id)
    if params[:id].blank? || Movie.find_publication(user_id, params[:id]).nil?
      return redirect_to(failure_not_found_movies_path)
    end

    @movie = Movie.find_publication(user_id, params[:id])
  end
  alias :my_show :show

  # 新規ムービー登録画面表示
  # 登録処理に入る前に同一セッションで
  # ファイルが既に生成されている場合はクリアする
  def new
    @title = 'ムービー新規登録'
    cleanup_temporary_file
    @movie = Movie.new(:visibility => @user.preference.movie_preference.default_visibility)
    render "form"
  end

  # 新規ムービー登録確認画面表示
  def confirm_before_create
    return redirect_to new_movie_path if params[:clear]
    @title = 'ムービー新規登録確認'
    @movie = Movie.new(params[:movie])

    return render_form if !@movie.valid?

    unless valid_movie_file?(params[:movie_file])
      @movie.errors.clear
      @movie.errors.add_to_base("ムービーファイルを添付してください。")
      return render_form
    end

    unless Movie.save_temporary_file(params[:movie_file], request.session_options[:id])
      @movie.errors.clear
      @movie.errors.add_to_base("ムービーファイルの保存に失敗しました。再度試してください。")
      return render_form
    end
    @movie_file = { :content_type => params[:movie_file].content_type,
                    :size => params[:movie_file].size }
    render "confirm"
  end

  # 新規ムービー登録完了処理
  def create
    @movie = Movie.new(params[:movie])
    return render_form if params[:cancel] || !@movie.valid?

    begin
      Movie.transaction do
        @movie.user = @user
        @movie.save

        unless @movie.save_movie_file(request.session_options[:id])
          raise "ERROR: temporary file not found or write protection to save directory"
        end
      end
    rescue Exception => ex
      logger.error{ "ERROR: #{ex.class} : #{ex.message}" }
      return redirect_to(failure_upload_movies_path)
    end
    if Mars::Movie::ResourceLoader['application']['realtime_convert']
      Movie.convert!(@movie.id)
    end
    redirect_to complete_after_create_movie_path(@movie)
  end

  # ムービー編集画面表示
  def edit
    @title = 'ムービー編集'
    if params[:id].blank?
      return redirect_to(failure_not_found_movies_path)
    end

    unless @user.movies.exists?(params[:id])
      return redirect_to(failure_not_found_movies_path)
    end

    @movie = @user.movies.find(params[:id])
    render "form"
  end

  # ムービー更新確認画面表示
  def confirm_before_update
    @title = 'ムービー更新確認'
    if params[:id].blank?
      return redirect_to(failure_not_found_movies_path)
    end

    unless @user.movies.exists?(params[:id])
      return redirect_to(failure_not_found_movies_path)
    end

    @movie = @user.movies.find(params[:id])

    return redirect_to edit_movie_path(@movie) if params[:clear]

    @movie.attributes = params[:movie]

    # 住所検索
    if search_address_request_for_mobile?
      return render_form
    end

    return render_form if !@movie.valid?
    render "confirm"
  end

  # ムービー更新完了処理
  def update
    if params[:id].blank?
      return redirect_to(failure_not_found_movies_path)
    end

    unless @user.movies.exists?(params[:id])
      return redirect_to(failure_not_found_movies_path)
    end

    @movie = @user.movies.find(params[:id])
    @movie.attributes = params[:movie]
    return render_form if params[:cancel] || !@movie.valid?
    return render_form unless @movie.save

    redirect_to complete_after_update_movie_path(@movie)
  end

  # ムービー削除完了処理
  def destroy
    if params[:id].blank?
      return redirect_to(failure_not_found_movies_path)
    end

    unless @user.movies.exists?(params[:id])
      return redirect_to(failure_not_found_movies_path)
    end

    @movie = Movie.find(params[:id])
    @movie.remove_movie_files
    Movie.destroy(@movie.id)
    redirect_to movies_path
  end

  # 検索機能実装
  #
  # params[:query] に指定された文字列を正規表現の空白文字にて分割し
  # いずれかの文字列を含むムービー情報を検索して表示
  def search
    @title = 'ムービー検索'
    @query_words = params[:query].blank? ? [] : params[:query].split(/\s/)
    @query_words.flatten!
    @query_words.compact!

    @movies = Movie.search_paginate(@query_words, @user.try(:id),
                                    paginate_options)
  end

  # トップページ新着ムービー
  def update_recent_movies
    @recent_movies = Movie.recents_paginate(@user.try(:id), paginate_options)
    render(:partial => 'recent_movies')
  end

  # トップページ自分のムービー
  def update_my_movies
    @movies = @user.movies.paginate(paginate_options)
    render(:partial => 'movies')
  end

  # ムービーを指定してサムネイル画像を返却する
  def thumbnail
    path = thumbnail_file_path(params[:id])
    File.open(path, 'r') do |image_file|
      send_data(image_file.read, :type => 'image/jpeg', :disposition => 'inline')
    end
  end

  # ムービーを指定してサムネイル画像を返却する
  def mobile_thumbnail
    path = mobile_thumbnail_file_path(params[:id])
    File.open(path, 'r') do |image_file|
      send_data(image_file.read, :type => 'image/jpeg', :disposition => 'inline')
    end
  end

  # Flash ムービーを取得する
  def flash_file
    path = flash_file_path(params[:id])
    if path.nil? # Flash ファイルがない
      send_data('', :type => 'video/x-flv', :disposition => 'inline')
    else
      File.open(path, 'r') do |file|
        send_data(file.read, :type => 'video/x-flv', :disposition => 'inline')
      end
    end
  end

  # 3gp ファイルを取得する
  def mobile_3gp_file
    path = mobile_3gp_file_path(params[:id])

    filesize = File.size(path)
    length = filesize
    range = request.env["HTTP_RANGE"]

    if range and /^bytes=(\d+)\-(\d+)$/ =~ range
      offset = $1.to_i
      limit  = $2.to_i
      length = limit - offset + 1
      response.headers["Content-Range"] = sprintf("bytes %d-%d/%d", offset, limit, filesize)
      content = IO::read(path, length, offset)
      status = 206
    else
      content = IO::read(path)
      status = 200
    end

    response.headers["Accept-Ranges"] = "bytes"
    response.headers["Content-Length"] = length
    response.headers["Cache-Control"] = "no-cache"
    response.headers["x-jphone-copyright"] = "no-transfer"

    render(:text => content, :status => status, :content_type => 'video/3gpp', :layout => false)
  end

  # 3g2 ファイルを取得する
  #
  # au 分割ダウンロード対応
  def mobile_3g2_file
    path = mobile_3g2_file_path(params[:id])

    filesize = File.size(path)
    range = request.env["HTTP_RANGE"]
    length = filesize

    if range and /^bytes=(\d+)\-(\d+)$/ =~ range
      offset = $1.to_i
      limit = $2.to_i
      length = limit - offset + 1
      response.headers["Content-Range"] = sprintf("bytes %d-%d/%d", offset, limit, filesize)
      response.headers["Content-Disposition"] = "devmpzz"
      content = IO::read(path, length, offset)
      status = 206
    else
      content = IO::read(path)
      status = 200
    end

    response.headers["Accept-Ranges"] = "bytes"
    response.headers["Content-Length"] = length

    # Content-Type の後に「; charset=utf-8」とかつかないようにするため
    response.headers["Content-Transfer-Encoding"] = "binary"
    render(:text => content, :status => status, :content_type => "video/3gpp2", :layout => false)
  end

  # ムービーマップを表示する
  def map
    @title = 'ムービーマップ'
    @movies = Movie.recents_for_map(@user.try(:id))
  end

  # ムービーマップ（携帯版）を表示する
  def map_for_mobile
    @title = 'ムービーマップ'
    set_map_for_mobile_params
    @records =
      Movie.by_latitude_range(@latitude_start, @latitude_end).
        by_longitude_range(@longitude_start, @longitude_end).
        paginate(paginate_options)
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    movies_path
  end

  # ムービーが見つからないエラー
  def failure_not_found
    @error_message = "ムービーが見つかりません"
    render "failure"
  end

  # アップロードエラー
  def failure_upload
    @error_message = "ファイルのアップロードに失敗しました。"
    render "failure"
  end

  private
  # SSL リクエスト判定
  def check_ssl_request
    @ssl_request = request.ssl?
    @http_url = "http://#{request.host}#{request.request_uri}"
    @https_url = "https://#{request.host}#{request.request_uri}"
  end

  # OpenSNP の設定読み込み
  def load_sns_conf
    @sns_conf = SnsConfig.find(:first)
  end

  def set_current_user
    @user = current_user
  end

  # ログイン状況をチェックし、未ログイン時はログイン画面にリダイレクト
  def login_required
    unless @user
      redirect_to(TOP_URL)
      return false
    end

    return true
  end

  # params で指定された php_session_id があれば session に登録する
  # XXX: モックがあります
  def update_php_session_id
    if params[:php_session_id] && !params[:php_session_id].empty?
      session[:php_session_id] = params[:php_session_id]
    end
  end

  # アップロードされたムービーファイルがムービーファイルとして正しいかチェックする
  # 問題がある場合は false 問題がない場合は true を返却する
  def valid_movie_file?(file)
    unless @user.movie_uploadable?
      @error_limited_size_over = true
      return false
    end
    case Movie.check_movie_file(file)
    when :ok;              return true
    when :blank;           @error_movie_file_not_found  = true
    when :size_over;       @error_file_size_over        = true
    when :invalid_extname; @error_extension_not_allowed = true
    end

    return false
  end

  # 新規登録時に仮置場にファイルがあれば削除する
  def cleanup_temporary_file
    unless Movie.estimate_temporary_file_path(request.session_options[:id]).nil?
      File.delete(Movie.estimate_temporary_file_path(request.session_options[:id]))
    end
  end

  # サムネイル画像の保存位置を取得
  #
  # 画像があればその画像を返却し、なければダミー画像を返却する
  def thumbnail_file_path(id)
    path = nil
    movie = nil
    if !id.blank? && Movie.exists?(id)
      movie = Movie.find(id)
      if movie.user == @user # 自分のムービー
        path = movie.thumbnail_file_path(:pc)
      else # 他人のムービー
        if Movie.find_publication(@user.try(:id), movie.id) # 閲覧可能
          path = movie.thumbnail_file_path(:pc)
        else # 閲覧不可
          path = Movie::THUMBNAIL_NOT_FOUND_PATH
        end
      end
    end

    if path.nil?
      case movie.convert_status
      when Movie::CONVERT_STATUSES[:yet]
        path = Movie::THUMBNAIL_NOT_YET_PATH
      when Movie::CONVERT_STATUSES[:error]
        path = Movie::THUMBNAIL_ERROR_PATH
      when Movie::CONVERT_STATUSES[:done]
        path = Movie::THUMBNAIL_NOT_FOUND_PATH
      end
    end

    return path if path && File.exists?(path)
    return Movie::THUMBNAIL_ERROR_PATH
  end

  # モバイルサムネイル画像の保存位置を取得
  #
  # 画像があればその画像を返却し、なければダミー画像を返却する
  def mobile_thumbnail_file_path(id)
    path = thumbnail_file_path(id)

    case path
    when Movie::THUMBNAIL_NOT_YET_PATH
      path = Movie::MOBILE_THUMBNAIL_NOT_YET_PATH
    when Movie::THUMBNAIL_ERROR_PATH
      path = Movie::MOBILE_THUMBNAIL_ERROR_PATH
    when Movie::THUMBNAIL_NOT_FOUND_PATH
      path = Movie::MOBILE_THUMBNAIL_NOT_FOUND_PATH
    else
      movie = Movie.find(id)
      path = movie.thumbnail_file_path(:mobile)
    end

    return path if path && File.exists?(path)
    return Movie::MOBILE_THUMBNAIL_ERROR_PATH
  end

  # Flash の保存位置を取得
  #
  # 画像があればその画像を返却し、なければダミー画像を返却する
  def flash_file_path(id)
    path = nil
    if !id.blank? && Movie.exists?(id)
      movie = Movie.find(id)
      if movie.user == @user # 自分のムービー
        case movie.convert_status
        when Movie::CONVERT_STATUSES[:done]
          path = File.join(Movie::DATA_DIR, "#{id}.flv")
        end
      else # 他人のムービー
        if Movie.find_publication(@user.try(:id), movie.id) # 閲覧可能
          path = File.join(Movie::DATA_DIR, "#{id}.flv")
        end
      end
      return path if File.exists?(path)
    end
    return nil
  end

  # 3gp の保存位置を取得
  #
  # 画像があればその画像を返却し、なければダミー画像を返却する
  def mobile_3gp_file_path(id)
    path = nil
    if !id.blank? && Movie.exists?(id)
      movie = Movie.find(id)
      if movie.user == @user # 自分のムービー
        case movie.convert_status
        when Movie::CONVERT_STATUSES[:done]
          path = File.join(Movie::DATA_DIR, "#{id}.3gp")
        end
      else # 他人のムービー
        if Movie.find_publication(@user.id, movie.id) # 閲覧可能
          path = File.join(Movie::DATA_DIR, "#{id}.3gp")
        end
      end
      return path if File.exists?(path)
    end
    return nil
  end

  # 3g2 の保存位置を取得
  #
  # 画像があればその画像を返却し、なければダミー画像を返却する
  def mobile_3g2_file_path(id)
    path = nil
    if !id.blank? && Movie.exists?(id)
      movie = Movie.find(id)
      if movie.user == @user # 自分のムービー
        case movie.convert_status
        when Movie::CONVERT_STATUSES[:done]
          path = File.join(Movie::DATA_DIR, "#{id}.3g2")
        end
      else # 他人のムービー
        if Movie.find_publication(@user.id, movie.id) # 閲覧可能
          path = File.join(Movie::DATA_DIR, "#{id}.3g2")
        end
      end
      return path if File.exists?(path)
    end
    return nil
  end

  # カレンダー表示に必要なパラメータ設定
  def set_calendar_params
    @calendar_year ||= Date.today.year
    @calendar_month ||= Date.today.month
    @calendar_movies = Movie.calendar(@user.try(:id), @calendar_year, @calendar_month)
  end

  def render_form
    @title = @movie.new_record? ? 'ムービー新規登録' : 'ムービー編集'
    render "form"
  end

  def paginate_options
    @paginate_options ||= {
      :page => params[:page] || 1,
      :per_page => params[:per_page] || 5,
    }
  end
end

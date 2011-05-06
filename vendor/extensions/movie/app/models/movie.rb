# == Schema Information
# Schema version: 20100227074439
#
# Table name: movies
#
#  id             :integer         not null, primary key
#  user_id        :integer
#  title          :string(255)
#  body           :text
#  created_at     :datetime
#  visibility     :integer
#  start_date     :date
#  end_date       :date
#  convert_status :integer
#  zoom           :integer
#  updated_at     :datetime
#  latitude       :decimal(9, 6)
#  longitude      :decimal(9, 6)
#

require 'mars/movie/converter'
require 'fileutils'

class Movie < ActiveRecord::Base
  enum_column :convert_status, {:yet => 0, :done => 1, :error => 2}
  CONVERT_LOG_FILE =
    File.expand_path(File.dirname(__FILE__) + '/../../log/convert.log')

  # ディレクトリ構成用
  BASE_DIR =
    File.expand_path(File.dirname(__FILE__) + '/../../data')
  # 再生用データを保存するディレクトリ
  DATA_DIR =
    File.expand_path(File.join(BASE_DIR, RAILS_ENV))

  # アップロードされたデータを保存するディレクトリ
  ORIGINAL_DATA_DIR = File.join(BASE_DIR, '/original/', RAILS_ENV)
  # 確認時に一時的に保存するディレクトリ
  TEMPORARY_DATA_DIR =
    File.expand_path(File.join(BASE_DIR, '/../tmp/movies/', RAILS_ENV))
  # サムネイル画像ディレクトリ
  THUMBNAIL_DATA_DIR =
    File.expand_path(File.join(BASE_DIR, '/thumbnail/', RAILS_ENV))
  # 未変換用サムネイル
  THUMBNAIL_NOT_YET_PATH =
    File.expand_path(File.join(THUMBNAIL_DATA_DIR, '..', 'not_yet.jpg'))
  # 変換エラー用サムネイル
  THUMBNAIL_ERROR_PATH =
    File.expand_path(File.join(THUMBNAIL_DATA_DIR, '..', 'error.jpg'))
  # ファイルがみつからない時用サムネイル
  THUMBNAIL_NOT_FOUND_PATH =
    File.expand_path(File.join(THUMBNAIL_DATA_DIR, '..', 'not_found.jpg'))
  # モバイル用未変換用サムネイル
  MOBILE_THUMBNAIL_NOT_YET_PATH =
    File.expand_path(File.join(THUMBNAIL_DATA_DIR, '..', 'mobile_not_yet.jpg'))
  # モバイル用変換エラー用サムネイル
  MOBILE_THUMBNAIL_ERROR_PATH =
    File.expand_path(File.join(THUMBNAIL_DATA_DIR, '..', 'mobile_error.jpg'))
  # モバイル用ファイルがみつからない時用サムネイル
  MOBILE_THUMBNAIL_NOT_FOUND_PATH =
    File.expand_path(File.join(THUMBNAIL_DATA_DIR, '..', 'mobile_not_found.jpg'))

  # アップロード許可サイズ上限(バイト)
  MAX_SIZE_OF_MOVIE_FILE = 10 * 1024 * 1024 # 1MB
  # アップロード許可サイズ上限(約メガバイト)
  MAX_SIZE_OF_MOVIE_FILE_MEGA = MAX_SIZE_OF_MOVIE_FILE / (1.0 * 1024 * 1024)
  # アップロード許可拡張子
  ALLOWED_EXTENSIONS = %w( .wmv .wma .rm .ram .swf .mov .mp3 .3gp .3g2 )

  belongs_to :user

  validates_presence_of(:title, :visibility)
  validates_length_of(:title, :in => 1..255)
  validates_inclusion_of(:visibility, :in => MoviePreference::VISIBILITIES.values)

  attr_protected :user_id

  before_create(:set_convert_status)
  before_validation(:date_merge)

  # 指定ユーザが閲覧可能な動画取得
  named_scope :by_visible_for_user, lambda{|user|
    wheres = ["movies.visibility in (?)"]
    wheres << "movies.visibility = ? AND movies.user_id in (?)"
    wheres << "movies.visibility = ? AND movies.user_id = ?"
    wheres = [wheres.map{|c| "(#{c})"}.join(" OR ")]
    wheres << "movies.convert_status = ?"
    where = wheres.map{|c| "(#{c})"}.join(" AND ")

    cond = [where,
            [MoviePreference::VISIBILITIES[:publiced],
             MoviePreference::VISIBILITIES[:member_only]],

            MoviePreference::VISIBILITIES[:friend_only],
            (user.friends.map(&:id) << user.id),

            MoviePreference::VISIBILITIES[:unpubliced],
            user.id,

            CONVERT_STATUSES[:done]
           ]
    {:conditions => cond}
  }

  named_scope :by_latitude_range, lambda { |lat_start, lat_end|
    {:conditions => ["movies.latitude > ? AND movies.latitude < ?", lat_start, lat_end]}
  }

  named_scope :by_longitude_range, lambda { |lng_start, lng_end|
    {:conditions => ["movies.longitude > ? AND movies.longitude < ?", lng_start, lng_end]}
  }

  named_scope :by_activate_users, lambda{
    {:conditions => ["users.approval_state = ?", 'active'], :include => [:user]}
  }

  # 指定されたユーザが閲覧できる
  # ムービーを新しい順に取得する
  # 上限として第二引数に数値を指定することで件数に制限をかけることが可能
  def self.recents(user_id, limit = 100)
    visibles = by_visible(user_id)

    visibles.find(:all, :order => 'movies.created_at desc', :limit => limit)
  end

  # ムービーマップ用ムービー一覧を取得
  def self.recents_for_map(user_id, limit = 100)
    visibles = by_visible(user_id)

    cond_s = []
    cond_s << "movies.latitude is not null"
    cond_s << "movies.longitude is not null"
    cond_s << "movies.zoom is not null"
    conditions = cond_s.collect {|c| "(#{c})"}.join(" AND ")

    visibles.find(:all, :conditions => conditions,
             :order => 'movies.created_at desc', :limit => limit)
  end

  # paginate 対応版最新ムービー一覧取得
  def self.recents_paginate(user_id, paginate_options = {})
    visibles = by_visible(user_id)
    order_by = 'movies.created_at desc'

    visibles.paginate(:all,
                 :order => 'movies.created_at desc',
                 :page => paginate_options[:page].to_i,
                 :per_page => paginate_options[:per_page].to_i)
  end

  # 本日ムービー取得
  def self.todays(user_id)
    visibles = by_visible(user_id)

    cond_s = []
    cond_v = []
    cond_s << 'start_date is not null'
    cond_s << 'start_date <= ?'
    cond_s << 'end_date >= ?'
    cond_v << Date.today.to_s(:db) << Date.today.to_s(:db)

    conditions = cond_v.unshift(cond_s.collect {|c| "(#{c})"}.join(" AND "))

    visibles.find(:all, :conditions => conditions, :order => 'movies.created_at desc')
  end

  # ムービー検索機能
  def self.search(words, user_id)
    words = words.delete_if do |w| w.blank? end
    words.uniq!
    return [] if words.empty?

    visibles = by_visible(user_id)
    query_conditions = generate_query_conditions(words)

    cond_s = [query_conditions.shift]
    cond_v = query_conditions

    conditions = cond_v.unshift(cond_s.collect{|c| "(#{c})"}.join(" AND "))
    visibles.find(:all, :conditions => conditions, :order => 'movies.created_at desc')
  end

  # paginate 対応版検索メソッド
  def self.search_paginate(query_words, user_id, paginate_options = {})
    words = query_words.dup
    words = words.delete_if do |w| w.blank? end
    words.compact!
    words.uniq!

    order_by = 'movies.created_at desc'

    visibles = by_visible(user_id)

    if words.empty?
      return visibles.paginate(:all,
                               :order => order_by,
                               :page => paginate_options[:page].to_i,
                               :per_page => paginate_options[:per_page].to_i)
    end

    query_conditions = generate_query_conditions(words)

    cond_s = [query_conditions.shift]
    cond_v = query_conditions

    conditions = cond_v.unshift(cond_s.collect{|c| "(#{c})"}.join(" AND "))
    paginate(:all, :conditions => conditions,
             :order => order_by, :include => {:user => :friendships},
             :page => paginate_options[:page].to_i,
             :per_page => paginate_options[:per_page].to_i)
  end

  # 引数に指定されたユーザが再生できる動画を取得します
  def self.find_publication(user_id, id)
    visibles = by_visible(user_id)
    cond_s = []
    cond_v = []
    cond_s << 'movies.id = ?'
    cond_v << id

    conditions = cond_v.unshift(cond_s.collect {|c| "(#{c})"}.join(" AND "))

    visibles.find(:first, :conditions => conditions, :order => 'movies.created_at desc')
  end

  # 指定された年月に表示されるムービー一覧を取得
  def self.calendar(user_id,
                    year = Date.today.year, month = Date.today.month)
    visibles = by_visible(user_id)

    cond_s = []
    cond_v = []

    first_date = Date.new(year, month, 1)
    last_date  = (first_date >> 1) - 1

    cond_s << 'start_date is not null'
    cond_s << '? <= end_date'
    cond_v << first_date.to_s(:db)
    cond_s << '? >= start_date'
    cond_v << last_date.to_s(:db)

    conditions = cond_v.unshift(cond_s.collect {|c| "(#{c})"}.join(" AND "))

    visibles.find(:all, :conditions => conditions, :order => 'movies.created_at desc')
  end

  # メンテナンス用動画ファイルと DB の整合性をチェックする
  #
  # サムネイル画像がない場合は自動生成する(ただし flv ファイルがある場合のみ)
  def self.check_compliance
    puts("Movie file check tool ver.1.0.0")

    error_count = 0
    self.find(:all).each do |movie|
      case movie.convert_status
      when CONVERT_STATUSES[:yet]
        if movie.original_file_path.nil?
          puts("ERROR: Original movie file not found for id[#{movie.id}]")
          puts("       You must copy from backup files match file name with " +
               "'#{movie.id}.*'")
          error_count += 1
        end
      when CONVERT_STATUSES[:done]
        ['flv', '3gp', '3g2'].each do |type|
          if movie.file_path(type).nil?
            puts("ERROR: Converted movie file not found " +
                 "in '#{movie.file_path(type, true)}'")
            puts("       You must copy from backup files match file name with "+
                 "'#{File.basename(movie.file_path(type, true))}'")
          error_count += 1
          end
        end
        [:pc, :mobile].each do |type|
          if movie.thumbnail_file_path(type).nil?
            flv_file = movie.file_path('flv')
            unless flv_file.nil?
              output = movie.thumbnail_file_path(type, true)
              Mars::Movie::Converter::generate_pc_thumbnail(flv_file, output)
              puts("INFO: Thumbnail file regenerated")
            end
          end
        end
      end
    end
    Dir.glob(File.join(DATA_DIR, '*.{flv,3gp,3g2}')) do |file|
      movie_id = File.basename(file, '.*').to_i
      unless self.exists?(movie_id)
        puts("ERROR: Record not found for movie file '#{file}'")
        puts("       You must delete this file.")
        error_count += 1
        next
      end
      movie = self.find(movie_id)
      if movie.convert_status != CONVERT_STATUSES[:done]
        puts("ERROR: Record not found for movie file '#{file}'")
        puts("       You must delete this file.")
        error_count += 1
      end
    end

    puts("All errors count #{error_count}")
    if error_count.zero?
      puts("Congratulation!!")
    else
      puts("You must fix these errors")
    end
  end

  # 指定された日付に表示するかどうかを判定する
  def display?(date)
    return false if start_date.blank?
    if end_date.blank?
      return date == start_date
    else
      return start_date <= date && date <= end_date
    end
  end

  # ログインユーザを引数に再生できるかを判定
  def playable?(player)
    return false unless convert_status == CONVERT_STATUSES[:done]
    if user == player
      return true
    else
      case visibility
      when MoviePreference::VISIBILITIES[:publiced]; return true
      when MoviePreference::VISIBILITIES[:member_only]; return true
      when MoviePreference::VISIBILITIES[:friend_only]
        return user.friends.include?(player)
      else return false
      end
    end
  end

  def visibility_to_s
    name = MoviePreference::VISIBILITIES.invert[visibility]
    I18n.t("movie.movie_preference.visibility_label.#{name}")
  end

  # 未変換動画の変換処理を行う
  #
  # 引数が指定されている場合はそのIDのムービーのみを変換
  def self.convert!(id = nil)
    log = Logger.new(CONVERT_LOG_FILE, 3, 1024 * 1024)
    # 処理の開始前に時間を取得しておく
    started_at = Time.now
    log.info("start movie converting at #{started_at}")

    # 未変換動画のうち検索時よりも一時間以上前に登録されたものに限定する
    cond_s = []; cond_v = []
    unless Mars::Movie::ResourceLoader['debug']['convert_now']
      cond_s << 'movies.created_at < ?'
      cond_v << 1.hour.ago.to_s(:db)
    end
    cond_s << 'convert_status = ?'
    cond_v << CONVERT_STATUSES[:yet]

    conditions = cond_v.unshift(cond_s.collect {|c| "(#{c})"}.join(" AND "))
    order_by = 'movies.created_at asc'

    movies = find(:all, :conditions => conditions, :order => order_by)

    unless id.nil?
      movie = find(id)
      movies = [movie] if movie.convert_status == CONVERT_STATUSES[:yet]
    end

    # 変換処理を実行する
    movies.each do |movie|
      log.info("converting for #{movie.title}")
      # 処理時間が30分を越えたら停止
      break if Time.now - started_at > 30 * 60
      begin
        Movie.transaction do
          input = movie.original_file_path
          logger.debug { "DEBUG(self.convert!) : original_file_path = #{input}" }
          if input.nil?
            movie.convert_status = CONVERT_STATUSES[:error]
            movie.save!
          else
            # 動画変換処理を行う
            # コンテナ修正
            unless Mars::Movie::Converter::fix_container(input)
              raise "ConvertError(fix_container)"
            end
            # Flash
            flv_file = movie.file_path('flv', true)
            unless Mars::Movie::Converter::convert_to_flv(input, flv_file)
              raise "ConvertError(flv)"
            end
            # 3gp
            output = movie.file_path('3gp', true)
            unless Mars::Movie::Converter::convert_to_3gp(input, output)
              raise "ConvertError(3gp)"
            end
            # 3g2
            output = movie.file_path('3g2', true)
            unless Mars::Movie::Converter::convert_to_3g2(input, output)
              raise "ConvertError(3g2)"
            end
            # サムネイル画像生成を行う
            # 失敗時は音声ファイルである例外は発生しない
            output = movie.thumbnail_file_path(:pc, true)
            Mars::Movie::Converter::generate_pc_thumbnail(flv_file, output)
            output = movie.thumbnail_file_path(:mobile, true)
            Mars::Movie::Converter::generate_pc_thumbnail(flv_file, output)
            # 変換処理が正常に完了したので、変換成功フラグを立てる
            movie.convert_status = CONVERT_STATUSES[:done]
            movie.save!
            # 元のファイルを削除する
            File.delete(input)
          end
        end
      rescue => e
        log.error('convert error!!')
        log.error("ERROR: #{e.class} : #{e.message}")
        # ステータスをエラーにする
        movie.convert_status = CONVERT_STATUSES[:error]
        movie.save!
        # 変換時に生成されたファイルを削除する
        File.delete(movie.file_path('flv')) if movie.file_path('flv')
        File.delete(movie.file_path('3gp')) if movie.file_path('3gp')
        File.delete(movie.file_path('3g2')) if movie.file_path('3g2')
        if movie.thumbnail_file_path(:pc)
           File.delete(movie.thumbnail_file_path(:pc))
        end
        if movie.thumbnail_file_path(:mobile)
          File.delete(movie.thumbnail_file_path(:mobile))
        end
      end
    end
    log.info("finish converting at #{Time.now}")
  end

  # 既に保存されているオリジナルファイルのパスを取得
  def original_file_path
    files = Dir.glob(File.join(ORIGINAL_DATA_DIR, "#{id}.*"))
    return nil unless files.size == 1
    return files.first
  end

  # 変換済みファイルのパスを取得
  #
  # type: 'flv', '3gp', '3g2'
  # not_exists: true ならばファイルがなくてもファイルパスを返却
  #             false ならばファイルがなければ nil を返却
  def file_path(type, not_exists = false)
    file_path = File.join(DATA_DIR, "#{id}.#{type}")
    return file_path if File.exists?(file_path) || not_exists
    return nil
  end

  # サムネイル画像ファイルのパスを取得
  #
  # type: :pc, :mobile
  # not_exists: true ならばファイルがなくてもファイルパスを返却
  #             false ならばファイルがなければ nil を返却
  def thumbnail_file_path(type, not_exists = false)
    file_path = nil
    if type == :mobile
      file_path = File.join(THUMBNAIL_DATA_DIR, "#{id}-mobile.jpg")
    else
      file_path = File.join(THUMBNAIL_DATA_DIR, "#{id}.jpg")
    end
    return file_path if File.exists?(file_path) || not_exists
    return nil
  end

  # 動画ファイルとして渡されたファイルが正しいかどうかを判定
  #
  # 戻り値は以下の通り
  # * :ok              問題なし
  # * :blank           ムービーファイルが空
  # * :size_over       ムービーファイルが上限サイズを越えている
  # * :invalid_extname ムービーファイルの拡張子が許可されていない
  def self.check_movie_file(file)
    return :blank if file.blank?
    return :size_over if file.size > MAX_SIZE_OF_MOVIE_FILE
    extension = File.extname(file.original_filename).downcase
    return :invalid_extname unless ALLOWED_EXTENSIONS.include?(extension)

    return :ok
  end

  # アップロードファイルの仮置場のパス
  def self.temporary_file_path(file, session_id)
    return File.join(TEMPORARY_DATA_DIR,
                     "#{session_id}" + File.extname(file.original_filename))
  end

  # 仮置場にファイルがあるば仮置場のファイルパスを返却
  def self.estimate_temporary_file_path(session_id)
    files = Dir.glob(File.join(TEMPORARY_DATA_DIR, "#{session_id}.*"))
    return nil unless files.size == 1
    return files.first
  end

  # 仮置場にファイルを保存する
  #
  # 成功時に true, 失敗時に false
  def self.save_temporary_file(file, session_id)
    File.open(temporary_file_path(file, session_id), 'wb') do |f|
      f.write(file.read)
    end
    return true
  rescue
    return false
  end

  # 既存 3g2 動画のブランドを修正する
  def self.fix_3g2_brand
    mp4box = Mars::Movie::Converter::MP4BOX

    find(:all).each do |movie|
      if movie.file_path('3g2')
        target = movie.file_path('3g2')
        cmd = "#{mp4box} -add #{target} -brand kddi -ab 3g2a #{target}_temp"
        system(cmd)
        cmd = "mv -f #{target}_temp #{target}"
        system(cmd)
      end
    end
  end

  # オリジナルのファイルを保存するパスを取得
  #
  # 仮置場にファイルがない場合などは例外
  def save_original_file_path(session_id)
    extname = File.extname(Movie.estimate_temporary_file_path(session_id))
    return File.join(ORIGINAL_DATA_DIR, "#{id}#{extname}")
  end

  # 仮置場のファイルをオリジナルファイル保存場所に移動
  # 成功時に true, 失敗時に false
  def save_movie_file(session_id)
    temporary_file_path = Movie.estimate_temporary_file_path(session_id)
    return false if temporary_file_path.nil?
    return false unless File.exists?(temporary_file_path)
    FileUtils.cp(temporary_file_path, save_original_file_path(session_id))
    FileUtils.rm(temporary_file_path)
    return true
  end

  # 関連する動画ファイルを削除する
  def remove_movie_files
    File.delete(original_file_path) if original_file_path
    File.delete(file_path('flv')) if file_path('flv')
    File.delete(file_path('3gp')) if file_path('3gp')
    File.delete(file_path('3g2')) if file_path('3g2')
    File.delete(thumbnail_file_path(:pc)) if thumbnail_file_path(:pc)
    File.delete(thumbnail_file_path(:mobile)) if thumbnail_file_path(:mobile)
  end

  # ファイルサイズ返却
  def file_size(ext)
    path = file_path(ext)
    path.blank? ? 0 : File.size(file_path(ext))
  end

  # 指定ユーザ閲覧可能動画一覧取得
  def self.by_visible(user)
    user = user.is_a?(User) ? user : User.find_by_id(user)
    return self.by_visible_for_user(user) if user
    return self.visibility_is(MoviePreference::VISIBILITIES[:publiced])
  end

  private
  def set_convert_status
    write_attribute(:convert_status, 0) if convert_status.nil?
  end

  # start_date と end_date の指定が正しいか判定
  def validate
    if start_date && end_date
      if start_date > end_date
        errors.add(:start_date, ' は終了日付よりも早く設定して下さい。')
      end
    end

    if start_date.blank? && end_date
      errors.add(:end_date,
                 ' を指定する際は開始日付を設定しなくてはなりません。')
    end
  end

  # 検索キーワードの配列を受け取り検索用の condtions 生成
  def self.generate_query_conditions(words)
    cond_s = []
    cond_v = []
    words.each do |word|
      cond_s << "movies.title like ?" << "movies.body like ?"
      cond_v << "%#{word}%" << "%#{word}%"
    end
    return cond_v.unshift(cond_s.collect {|c| "(#{c})"}.join(" OR "))
  end

  def date_merge
    if !start_date.blank? && end_date.blank?
      write_attribute(:end_date, start_date)
    end
  end
end

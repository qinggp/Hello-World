require 'net/pop'

class MovieMailManager < ActionMailer::Base
  include Mars::MailReceivable
  LOCKFILE   = File.expand_path(File.join(File.dirname(__FILE__), '..', '..',
                                          'tmp', 'checkmail.lock'))
  @@category_prefix = "m"
  cattr_reader :category_prefix

  # メール受信メソッド
  def receive(email)
    logger.info("proccessing for #{email.subject} from #{email.from[0]}")

    raise UnknownMailAddress.new(email) if !valid_email?(email)

    user = User.find_by_id(extract_user_id_by_to(first_to_me(email)))
    visibility = user.preference.movie_preference.default_visibility

    raise MovieLimitOver.new(email)     unless user.movie_uploadable?
    raise NotAttachedError.new(email)   unless email.has_attachments?
    raise InvalidAttachFile.new(email)  unless valid_attachments?(email.attachments)

    movie = user.movies.build(:title => normalize_subject_for_db(email),
                              :body => normalize_body_for_db(email),
                              :visibility => visibility)

    Movie.transaction do
      movie.save!
      attachment = email.attachments.first
      File.open(save_path(movie.id, attachment.original_filename), 'wb') do |file|
        file.write(attachment.read)
      end
    end
    MovieMobileReplyMailer.deliver_complete(user, movie)
    if Mars::Movie::ResourceLoader['application']['realtime_convert']
      Movie.convert!(movie.id)
    end
    logger.info("completed for #{email.subject} from #{email.from[0]}")
  rescue UnknownMailAddress => e
    MovieMobileReplyMailer.deliver_unknown_address(email.from[0])
    logger.error("unknown mail address: #{email.from[0]}")
  rescue MovieLimitOver => e
    MovieMobileReplyMailer.deliver_error(user, email.subject,
                                    '容量オーバーです。不要な動画を削除してください')
    logger.error("movie limit over")
  rescue NotAttachedError => e
    MovieMobileReplyMailer.deliver_error(user, email.subject,
                                    '添付ファイルが一つもありません。')
    logger.error("not attached movie file")
  rescue InvalidAttachFile => e
    if e.email.attachments.size != 1
      MovieMobileReplyMailer.deliver_error(user, email.subject,
                                      "添付ファイルが複数添付されています。")
      logger.error("multi files attached")
    else
      case Movie.check_movie_file(e.email.attachments.first)
      when :blank
        MovieMobileReplyMailer.deliver_error(user, email.subject, 
                                        "動画ファイルのサイズが0です。")
        logger.error("attached file is blank")
      when :size_over
        message = "動画ファイルサイズが上限を越えています。\n"
        message += "動画ファイルのサイズ上限は #{Movie::MAX_SIZE_OF_MOVIE_FILE} バイト"
        message += "（約#{Movie::MAX_SIZE_OF_MOVIE_FILE_MEGA}MB）です。"
        MovieMobileReplyMailer.deliver_error(user, email.subject, message)
        logger.error("attached file is very large")
      when :invalid_extname
        message = "動画ファイルの拡張子が許可されていません。\n"
        message += "許可されている拡張子の一覧:\n"
        message += Movie::ALLOWED_EXTENSIONS.join(' ')
        MovieMobileReplyMailer.deliver_error(user, email.subject, message)
        logger.error("attached file extname not allowed" +
                   " #{e.email.attachments.first.original_filename}")
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    MovieMobileReplyMailer.deliver_error(user, email.subject, "件名が入力されていません。")
    logger.error("ActiveRecord::RecordInvalid: " + movie.errors.full_messages.join("\n"))
  rescue => e
    logger.error(e)
    message = "サーバトラブルによるエラーが発生しました。\n"
    message += "しばらくたってから送信し直してください。\n"
    MovieMobileReplyMailer.deliver_error(user, email.subject, message)
    logger.error("system error occured!!#{e.to_s}")
  end
  
  # メールチェックのみを行う
  def self.check_mail
    # ロックファイルがある場合は即座に終了
    return if File.exists?(LOCKFILE)
    # ロックファイル生成
    File.open(LOCKFILE, "w") do |f| f.puts("locked at #{Time.now}") end
    logger = Logger.new(LOGFILE, 3, 1024 * 1024)
    logger.level = Mars::Movie::ResourceLoader['debug']['mail_manager_log_level'] || Logger::INFO
    logger.info("Starting mail checks at #{Time.now}")
    pop = Net::POP3.new(POP_SERVER, PORT)
    pop.start(ACCOUNT, PASSWORD)
    unless pop.mails.empty?
      pop.each_mail do |mail|
        receive(mail.pop)
        mail.delete unless Mars::Movie::ResourceLoader['debug']['disable_remove_mail']
      end
    end
    pop.finish
    logger.info("Finished mail checks #{Time.now}")
  ensure
    # ロックファイル削除
    File.delete(LOCKFILE) if File.exists?(LOCKFILE)
  end

  private
  # 添付ファイルの正当性チェック
  #
  # 正しければ true
  def valid_attachments?(attachments)
    return false if attachments.size != 1
    return true if Movie.check_movie_file(attachments.first) == :ok
    return false
  end

  # 動画ファイルを保存する場所
  def save_path(movie_id, filename)
    File.join(Movie::ORIGINAL_DATA_DIR, "#{movie_id}#{File.extname(filename)}")
  end

  class MailManagerError < StandardError
    attr_reader :email

    def initialize(email)
      @email = email
    end
  end

  class NotAttachedError < MailManagerError; end
  class UnknownMailAddress < MailManagerError; end
  class InvalidAttachFile < MailManagerError; end
  class MovieLimitOver < MailManagerError; end
end

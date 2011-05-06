require 'nkf'

class MovieMobileReplyMailer < Mars::Iso2022jpMailer
  include Mars::MailSendable

  # 登録が正常に完了した場合
  def complete(user, movie)
    setup_subject!('動画登録完了通知')
    @body    = { 'user' => user, 'movie' => movie }
    setup_send_info!(:user => user)
  end

  # 登録されていないメールアドレスからの投稿
  def unknown_address(address)
    setup_subject!('動画登録エラー通知')
    @reply_to   = address
    @recipients = address
    @from       = SnsConfig.admin_mail_address
    @sent_on    = Time.now
    @headers    = {}
    @body       = { 'address' => address }
  end

  # 何かしらのエラーによる失敗通知
  def error(user, title, message)
    setup_subject!('動画登録エラー通知')
    @headers    = {}
    @body       = { 'user' => user, 'title' => title, 'message' => message }
    setup_send_info!(:user => user)
  end
end

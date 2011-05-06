# 名前変更依頼通知
class RequestNewNameNotifier < Mars::Iso2022jpMailer
  include Mars::MailSendable

  # 名前変更依頼メール送信
  #
  # ==== 引数
  #
  # * user - ユーザレコード
  # * request - リクエスト情報
  def notification(user, request)
    setup_subject!("名前変更依頼")
    @body["user"] = user
    @body["request"] = request
    from SnsConfig.admin_mail_address
    recipients SnsConfig.admin_mail_address
    sent_on  Time.now
  end
end

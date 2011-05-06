# お問い合わせメール
class AskNotifier < Mars::Iso2022jpMailer
  include Mars::MailSendable

  # お問い合わせメール
  def notification(user)
    setup_subject!("お問い合わせ内容のご確認")
    @body["user"] = user
    setup_send_info!(:user => user)
  end

  # お問い合わせメール（管理人へ）
  def notification_to_admin(user, request)
    setup_subject!("お問い合わせ内容のご確認")
    @body = {"user" => user, "request" => request}
    from user.login
    recipients SnsConfig.admin_mail_address
    sent_on Time.now
  end
end

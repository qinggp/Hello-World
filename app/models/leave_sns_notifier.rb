# SNS退会時のメールお知らせ
class LeaveSnsNotifier < Mars::Iso2022jpMailer
  include Mars::MailSendable

  # 管理人にお知らせ
  def notification_to_admin(user)
    setup_subject!("#{user.name_and_full_real_name}さんが退会しました")
    @body["user"] = user
    from SnsConfig.admin_mail_address
    recipients SnsConfig.admin_mail_address
    reply_to  user.login
    sent_on  Time.now
  end

  # 退会ユーザにお知らせ
  def notification_to_leave_user(user)
    setup_subject!("退会手続きが完了しました")
    @body["user"] = user
    setup_send_info!(:user => user)
  end
end

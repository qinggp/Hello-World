class UserMailer < Mars::Iso2022jpMailer
  include Mars::MailSendable

  #管理者がユーザー削除時に同時に送信されるメール
  def destroy_admin_user(user,reason)
    setup_subject!("#{user.full_real_name}さんが退会しました")
    @body["user"] = user
    @body["reason"] = reason

    from SnsConfig.admin_mail_address
    recipients SnsConfig.admin_mail_address
    reply_to  user.login
    sent_on  Time.now
  end
end

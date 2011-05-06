# トモダチ招待メール
class InviteNotifier < Mars::Iso2022jpMailer
  include Mars::MailSendable

  # トモダチ招待メール送信
  def notification(invite)
    current_user = invite.user
    setup_subject!("#{current_user.full_real_name}さんから #{SnsConfig.title} への招待状が届いています")
    @body = {"current_user" => current_user, "invite" => invite}
    sender_email = invite.mail_sender_me? ? current_user.login : SnsConfig.admin_mail_address
    from sender_email
    recipients invite.email
    reply_to  sender_email
    sent_on  Time.now
  end
end

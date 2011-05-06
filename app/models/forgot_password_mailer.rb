class ForgotPasswordMailer < Mars::Iso2022jpMailer
  include Mars::MailSendable
  
  def forgot_password(password)
    setup_subject!("パスワード再発行用URL")
    @body = {:user => password.user,
      :reset_code => password.reset_code}
    setup_send_info!(:user => password.user)
  end

  def reset_password(user)
    setup_subject!('あなたのパスワードが再発行されました')
    @body = {:user => user}
    setup_send_info!(:user => user)
  end
end

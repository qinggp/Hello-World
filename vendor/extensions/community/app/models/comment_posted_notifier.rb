class CommentPostedNotifier < Mars::Iso2022jpMailer
  include Mars::MailSendable

  def notice_comment(comment, user, mobile = false)
    setup_subject!("#{comment.community.name}")
    @body["comment"] = comment
    setup_send_info!(:user => user, :mobile => mobile)
  end
end

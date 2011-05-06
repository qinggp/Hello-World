class BlogCommentNotifier < Mars::Iso2022jpMailer
  include Mars::MailSendable

  # お知らせメール
  def notification(options)
    entry = options[:blog_comment].blog_entry
    @subject = base64("【#{SnsConfig.title}ブログコメント#{'修正' if options[:edited]}】" + entry.title)
    @body["blog_entry"] = entry
    @body["blog_comment"] = options[:blog_comment]
    @body["edited"] = options[:edited]
    setup_send_info!(:user => entry.user)
  end
end

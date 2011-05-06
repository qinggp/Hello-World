# ブログ記事メール投稿
class BlogEntryReceiver < ActionMailer::Base
  include Mars::MailReceivable

  @@category_prefix = "b"
  cattr_reader :category_prefix

  # メール受信
  def receive(email)
    if valid_email?(email)
      user = User.find(extract_user_id_by_to(first_to_me(email)))
      BlogEntry.transaction do
        entry = BlogEntry.new(:title => normalize_subject_for_db(email),
                              :body => normalize_body_for_db(email),
                              :user_id => user.id,
                              :visibility => user.preference.blog_preference.email_post_visibility,
                              :comment_restraint => user.preference.blog_preference.comment_restraint_for_email)
        entry.save!
        save_attachments_files!(entry, email)
        user.has_role!(:blog_entry_author, entry)
      end
    end
  rescue ActiveRecord::ActiveRecordError => ex
    logger.debug{ ex }
  end

  private

  # メールの添付ファイルをDB登録
  def save_attachments_files!(entry, email)
    if email.has_attachments? && !email.attachments.blank?
      email.attachments.each_with_index do |file, i|
        entry.blog_attachments.build(:position => (i+1), :image => file)
      end
    end
    entry.blog_attachments.map(&:save!)
  end
end

# コミュニティスレッドへの返信メール投稿
class CommunityReplyReceiver < ActionMailer::Base
  include Mars::MailReceivable

  @@category_prefix = "r"
  cattr_reader :category_prefix

  # メール受信
  def receive(email)
    if valid_email?(email)
      user = User.find(extract_user_id_by_to(first_to_me(email)))
      thread = CommunityThread.find(extract_thread_id_by_to(first_to_me(email)))
      parent_id = extract_parent_id_by_to(first_to_me(email))

      CommunityReply.transaction do
        reply = CommunityReply.new(:title => normalize_subject_for_db(email),
                                   :content => normalize_body_for_db(email),
                                   :user_id => user.id,
                                   :community_id => thread.community_id,
                                   :thread_id => thread.id,
                                   :parent_id => parent_id)
        reply.save!
        save_attachments_files!(reply, email)
      end
    end
  rescue ActiveRecord::ActiveRecordError => ex
    logger.debug{ ex }
  end

  private

  # メールの添付ファイルをDB登録
  def save_attachments_files!(reply, email)
    if email.has_attachments? && !email.attachments.blank?
      email.attachments.each_with_index do |file, i|
        reply.attachments.build(:position => (i+1), :image => file)
      end
    end
    reply.attachments.map(&:save!)
  end

  # ToアドレスからコミュニティのスレッドIDを取り出す
  def extract_thread_id_by_to(to)
    return $2 if to.match(/\A\w+-(\d+)-(\d+)/)
    return ""
  end

  # Toアドレスから返信元のIDを取り出す
  def extract_parent_id_by_to(to)
    return $3 if to.match(/\A\w+-(\d+)-(\d+)-(\d+)/)
    return nil
  end
end


# コミュニティトピックメール投稿
class CommunityTopicReceiver < ActionMailer::Base
  include Mars::MailReceivable

  @@category_prefix = "t"
  cattr_reader :category_prefix

  # メール受信
  def receive(email)
    if valid_email?(email)
      user = User.find(extract_user_id_by_to(first_to_me(email)))
      community = Community.find(extract_community_id_by_to(first_to_me(email)))
      CommunityTopic.transaction do
        topic = community.topics.new(:title => normalize_subject_for_db(email),
                                     :content => normalize_body_for_db(email),
                                     :user_id => user.id)
        topic.save!
        save_attachments_files!(topic, email)
      end
    end
  rescue ActiveRecord::ActiveRecordError => ex
    logger.debug{ ex }
  end

  private

  # メールの添付ファイルをDB登録
  def save_attachments_files!(topic, email)
    if email.has_attachments? && !email.attachments.blank?
      email.attachments.each_with_index do |file, i|
        topic.attachments.build(:position => (i+1), :image => file)
      end
    end
    topic.attachments.map(&:save!)
  end

  # ToアドレスからコミュニティIDを取り出す
  def extract_community_id_by_to(to)
    return $2 if to.match(/\A\w+-(\d+)-(\d+)/)
    return ""
  end
end

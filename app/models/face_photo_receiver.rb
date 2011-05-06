# プロフィール顔写真アップロード
class FacePhotoReceiver < ActionMailer::Base
  include Mars::MailReceivable

  @@category_prefix = "p"
  cattr_reader :category_prefix

  # メール受信
  def receive(email)
    if valid_email?(email)
      user = User.find(extract_user_id_by_to(first_to_me(email)))
      ActiveRecord::Base.transaction do
        save_attachment_file!(user, email)
      end
    end
  rescue ActiveRecord::ActiveRecordError => ex
    logger.debug{ ex }
  end

  private

  # メールの添付ファイル設定
  def save_attachment_file!(user, email)
    if email.has_attachments? && !email.attachments.blank?
      user.photo_attributes =
        {:face_photo_attributes => {:image => email.attachments.first}}
      user.save!
    end
  end
end

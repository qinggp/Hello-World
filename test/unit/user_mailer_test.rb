require File.dirname(__FILE__) + '/../test_helper'

class UserMailerTest < ActionMailer::TestCase
  tests UserMailer

  def setup
    setup_emails
  end

  # メッセージ通知メール送信
  def test_notification
    user = User.make
    reason = '削除・退会理由'

    UserMailer.deliver_destroy_admin_user(user, reason)
    assert_equal  1, @emails.size
    mail = @emails.first
    assert_equal [SnsConfig.find(:first).admin_mail_address], mail.to
    assert_equal [user.login], mail.reply_to
    assert_equal [SnsConfig.find(:first).admin_mail_address], mail.from
    assert_match /さんが退会しました/, NKF.nkf("-mJw", mail.subject)
    assert_match /#{user.first_real_name}/, NKF.nkf("-mJw", mail.subject)
    assert_match /#{user.id}/, mail.body
    assert_match /#{user.first_real_name}/, mail.body
  end
end

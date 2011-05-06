require File.dirname(__FILE__) + '/../test_helper'

class MessageNotifierTest < ActionMailer::TestCase
  tests MessageNotifier

  def setup
    setup_emails
  end

  # メッセージ通知メール送信
  def test_notification
    sender = User.make
    receiver = User.make

    message = Message.make(:sender => sender, :receiver => receiver)

    MessageNotifier.deliver_notification(message)
    assert_equal  1, @emails.size
    mail = @emails.first
    assert_equal [receiver.login], mail.to
    assert_equal [receiver.login], mail.reply_to
    assert_equal [SnsConfig.admin_mail_address], mail.from
    assert_match /メッセージ/, NKF.nkf("-mJw", mail.subject)
    assert_match /メッセージボックス/, mail.body
    assert_match /#{message.id}/, mail.body
  end
end

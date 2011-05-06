require File.dirname(__FILE__) + '/../test_helper'

# 招待メールテスト
class InviteNotifierTest < ActionMailer::TestCase
  tests InviteNotifier

  def setup
    setup_emails
  end

  # 招待メール送信
  def test_notifier
    current_user = User.make
    invite = Invite.make(:user => current_user)

    InviteNotifier.deliver_notification(invite)
    assert_equal  1, @emails.size
    mail = @emails.first
    assert_equal [invite.email], mail.to
    assert_equal [SnsConfig.admin_mail_address], mail.reply_to
    assert_equal [SnsConfig.admin_mail_address], mail.from
    assert_match /#{current_user.full_real_name}/, NKF.nkf("-mJw", mail.subject)
    assert_match /#{invite.body}/, mail.body
  end

  # 招待メール送信（自分のアドレスを差出人にする）
  def test_notifier_by_me
    current_user = User.make
    invite = Invite.make(:user => current_user,
                         :mail_sender_me => "true", :body => "")
    InviteNotifier.deliver_notification(invite)
    assert_equal  1, @emails.size
    mail = @emails.first
    assert_equal [invite.email], mail.to
    assert_equal [current_user.login], mail.reply_to
    assert_equal [current_user.login], mail.from
    assert_match /#{current_user.full_real_name}/, NKF.nkf("-mJw", mail.subject)
    assert_nil mail.body.match(/からあなたへのメッセージ/)
  end
end

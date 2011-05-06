require File.dirname(__FILE__) + '/../test_helper'

class LeaveSnsNotifierTest < ActionMailer::TestCase
  tests LeaveSnsNotifier

  def setup
    setup_emails
  end

  # 管理人にお知らせ
  def test_notification_to_admin
    user = User.make(:leave_reason => "testtest")

    LeaveSnsNotifier.deliver_notification_to_admin(user)
    assert !@emails.empty?

    sent = @emails.first
    assert_equal [SnsConfig.admin_mail_address], sent.to
    assert_equal [user.login], sent.reply_to
    assert_equal [SnsConfig.admin_mail_address], sent.from
    assert_match /testtest/, sent.body
    assert_match /#{user.full_real_name}/, sent.body
    assert_match /#{user.name}\(#{user.full_real_name}\)/, NKF.nkf("-mJw", sent.subject)
  end

  # 退会ユーザにお知らせ
  def test_notification_to_leave_user
    user = User.make

    LeaveSnsNotifier.deliver_notification_to_leave_user(user)
    assert !@emails.empty?

    sent = @emails.first
    assert_equal [user.login], sent.to
    assert_equal [user.login], sent.reply_to
    assert_equal [SnsConfig.admin_mail_address], sent.from
  end
end

require File.dirname(__FILE__) + '/../test_helper'

# お問い合わせメールテスト
class AskNotifierTest < ActionMailer::TestCase
  tests AskNotifierTest

  def setup
    setup_emails
  end

  # お問い合わせメール送信
  def test_notifier
    @user = User.make_unsaved(:ask_body => "toiawase")

    AskNotifier.deliver_notification(@user)
    assert_equal 1, @emails.size

    mail = @emails.first
    assert_equal [@user.login], mail.to
    assert_match /お問い合わせ内容のご確認/, NKF.nkf("-mJw", mail.subject)
    assert_match /toiawase/, mail.body
  end

  # お問い合わせメール送信（ログイン時）
  def test_notifier_with_logged_in
    @user = User.make(:ask_body => "toiawase",
                      :error_message => "error_message",
                      :errored_at => "2009/1/13",
                      :error_page_url => "http://localhost:3000/error_page_url",
                      :error_repeatability => User::ERROR_REPEATABILITIES[:yes])

    AskNotifier.deliver_notification(@user)
    assert_equal 1, @emails.size

    mail = @emails.first
    assert_match /#{@user.error_message}/, mail.body
    assert_match /#{@user.errored_at}/, mail.body
    assert_match /#{@user.error_page_url}/, mail.body
  end

  # お問い合わせメール送信（管理人へ）
  def test_notifier_to_admin
    @user = User.make_unsaved(:ask_body => "toiawase")

    AskNotifier.deliver_notification_to_admin(@user, @request)
    assert_equal 1, @emails.size

    mail = @emails.first
    assert_equal [SnsConfig.admin_mail_address], mail.to
    assert_equal [@user.login], mail.from
    assert_match /お問い合わせ内容のご確認/, NKF.nkf("-mJw", mail.subject)
    assert_match /toiawase/, mail.body
  end
end

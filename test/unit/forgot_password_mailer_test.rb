require File.dirname(__FILE__) + '/../test_helper'

class ForgotPasswordMailerTest < ActionMailer::TestCase
  tests ForgotPasswordMailer

  def setup
    setup_emails
  end

  # パスワード再発行URLお知らせメール送信
  def test_forget_password
    user = User.make
    f_pass = ForgotPassword.make(:email => user.login, :user => user)

    ForgotPasswordMailer.deliver_forgot_password(f_pass)
    assert !@emails.empty?

    sent = @emails.first
    assert_equal [user.login], sent.to
    assert_equal [user.login], sent.reply_to
    assert_equal [SnsConfig.admin_mail_address], sent.from
    assert_match /#{user.login}/, sent.body
  end

  # パスワード再発行お知らせメール送信
  def test_reset_password
    user = User.make

    ForgotPasswordMailer.deliver_reset_password(user)
    assert !@emails.empty?

    sent = @emails.first
    assert_equal [user.login], sent.to
    assert_equal [user.login], sent.reply_to
    assert_equal [SnsConfig.admin_mail_address], sent.from
    assert_match /#{user.login}/, sent.body
  end
end

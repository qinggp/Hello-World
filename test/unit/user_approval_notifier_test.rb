require File.dirname(__FILE__) + '/../test_helper'

class UserApprovalNotifierTest < ActionMailer::TestCase
  tests UserApprovalNotifier

  def setup
    setup_emails
  end

  # 承認待ちユーザへの参加承認お知らせ
  def test_approve_notification
    invite_user = User.make
    invite_user.reason = "メッセージ、承認されました"

    UserApprovalNotifier.deliver_approve_notification(invite_user)
    assert_equal  1, @emails.size
    mail = @emails.first
    assert_equal [invite_user.login], mail.to
    assert_equal [invite_user.login], mail.reply_to
    assert_equal [SnsConfig.admin_mail_address], mail.from
    assert_match /#{invite_user.reason}/, mail.body
  end

  # 承認者へのユーザ承認のお知らせ
  def test_approve_notification_to_approver
    invite_user = User.make
    approver = User.make

    UserApprovalNotifier.deliver_approve_notification_to_approver(approver, invite_user)
    assert_equal  1, @emails.size
    mail = @emails.first
    assert_equal [approver.login], mail.to
    assert_equal [approver.login], mail.reply_to
    assert_equal [SnsConfig.admin_mail_address], mail.from
  end

  # プロフィール変更依頼
  def test_rewrite_request
    user = User.make
    user.reason = "プロフィール情報、修正してください"

    UserApprovalNotifier.deliver_rewrite_request(user)
    assert_equal  1, @emails.size
    mail = @emails.first
    assert_equal [user.login], mail.to
    assert_equal [user.login], mail.reply_to
    assert_equal [SnsConfig.admin_mail_address], mail.from
    assert_match /#{user.reason}/, mail.body
  end

  # 参加拒否
  def test_reject
    user = User.make
    user.reason = "参加拒否"

    UserApprovalNotifier.deliver_reject(user)
    assert_equal  1, @emails.size
    mail = @emails.first
    assert_equal [user.login], mail.to
    assert_equal [user.login], mail.reply_to
    assert_equal [SnsConfig.admin_mail_address], mail.from
    assert_match /#{user.reason}/, mail.body
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class CommunityApprovalNotifierTest < ActionMailer::TestCase
  tests CommunityApprovalNotifier

  def setup
    setup_emails
  end

  # 承認拒否通知メール送信
  def test_rejection
    community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_member],
                               :participation_notice => false)

    user = User.make
    judge = User.make
    community.receive_application(user)

    pending = PendingCommunityUser.by_community(community).by_pending_user(user).first
    reject_message = "ダメです\nまた今度"

    pending.update_attributes!(:reject_message => reject_message, :judge_id => judge.id)
    pending.reject!

    assert_equal 1, @emails.size

    sent = @emails.first
    assert_equal [user.login], sent.to
    assert_equal [user.login], sent.reply_to
    assert_equal [SnsConfig.admin_mail_address], sent.from
    assert_match /参加が承認されませんでした/, NKF.nkf("-mJw", sent.subject)
    assert_match /管理人より一言/, sent.body

    # 同じような内容で、メッセージが作成される
    # 件名は、システム名が入って無いので若干違う
    # またbodyは、文字コードが異なるので、変換してから比較する
    message = Message.sender_id_is(judge.id).receiver_id_is(user.id).first
    assert_equal message.body, NKF::nkf("-w8", sent.body)
    assert_match /参加が承認されませんでした/, message.subject
  end

  # 承認通知メール送信
  def test_acceptance
    community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_member],
                               :participation_notice => false)

    user = User.make
    judge = User.make
    community.receive_application(user)
    pending = PendingCommunityUser.by_community(community).by_pending_user(user).first

    pending.update_attributes!(:judge_id => judge.id)
    pending.activate!

    assert_equal 1, @emails.size

    sent = @emails.first
    assert_equal [user.login], sent.to
    assert_equal [user.login], sent.reply_to
    assert_equal [SnsConfig.admin_mail_address], sent.from
    assert_match /承認されました/, NKF.nkf("-mJw", sent.subject)
    assert_match /承認されました/, sent.body

    # 同じような内容で、メッセージが作成される
    # 件名は、システム名が入って無いので若干違う
    # またbodyは、文字コードが異なるので、変換してから比較する
    message = Message.sender_id_is(judge.id).receiver_id_is(user.id).first
    assert_equal message.body, NKF::nkf("-w8", sent.body)
    assert_match /承認されました/, message.subject
  end
end

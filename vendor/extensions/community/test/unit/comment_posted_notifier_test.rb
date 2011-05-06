require File.dirname(__FILE__) + '/../test_helper'

class CommentPostedNotifierTest < ActionMailer::TestCase
  tests CommentPostedNotifier

  def setup
    setup_emails
  end

  # イベントを作成したときの書き込み通知テスト
  def test_notice_comment_when_creating_event
    @current_user = User.make
    community = set_community_and_has_role
    community.change_comment_notice_acceptable(@current_user)
    community.change_comment_notice_acceptable_for_mobile(@current_user)
    event = community.events.make(:author => User.make)

    assert_equal 2, @emails.size

    sent = @emails.first
    assert_equal [@current_user.login], sent.to
    assert_equal [@current_user.login], sent.reply_to
    assert_equal [SnsConfig.admin_mail_address], sent.from
    assert_match /#{community.name}/, NKF.nkf("-mJw", sent.subject)
    assert_match /#{event.content}/, sent.body

    mobile_mail = @emails.second
    assert_equal [@current_user.mobile_email], mobile_mail.to
    assert_equal [@current_user.mobile_email], mobile_mail.reply_to
  end

  # マーカーを作成したときの書き込み通知テスト
  def test_notice_comment_when_creating_marker
    @current_user = User.make
    community = set_community_and_has_role
    community.change_comment_notice_acceptable(@current_user)
    community.change_comment_notice_acceptable_for_mobile(@current_user)
    marker = community.markers.make(:author => User.make)

    assert_equal 2, @emails.size

    sent = @emails.first
    assert_equal [@current_user.login], sent.to
    assert_equal [@current_user.login], sent.reply_to
    assert_equal [SnsConfig.admin_mail_address], sent.from
    assert_match /#{community.name}/, NKF.nkf("-mJw", sent.subject)
    assert_match /#{marker.content}/, sent.body

    mobile_mail = @emails.second
    assert_equal [@current_user.mobile_email], mobile_mail.to
    assert_equal [@current_user.mobile_email], mobile_mail.reply_to
  end

  # トピックを作成したときの書き込み通知テスト
  def test_notice_comment_when_creating_topic
    @current_user = User.make
    community = set_community_and_has_role
    community.change_comment_notice_acceptable(@current_user)
    community.change_comment_notice_acceptable_for_mobile(@current_user)
    topic = community.topics.make(:author => User.make)

    assert_equal 2, @emails.size

    sent = @emails.first
    assert_equal [@current_user.login], sent.to
    assert_equal [@current_user.login], sent.reply_to
    assert_equal [SnsConfig.admin_mail_address], sent.from
    assert_match /#{community.name}/, NKF.nkf("-mJw", sent.subject)
    assert_match /#{topic.content}/, sent.body

    mobile_mail = @emails.second
    assert_equal [@current_user.mobile_email], mobile_mail.to
    assert_equal [@current_user.mobile_email], mobile_mail.reply_to
  end

  # 返信したときの書き込み通知テスト
  def test_notice_comment_when_creating_reply
    @current_user = User.make
    community = set_community_and_has_role
    community.change_comment_notice_acceptable(@current_user)
    community.change_comment_notice_acceptable_for_mobile(@current_user)

    # ここは自分が作成したので、メール通知されない
    topic = community.topics.make(:author => @current_user)

    # ここでメール通知される
    reply = topic.replies.make(:author => User.make, :community => community)

    assert_equal 2, @emails.size

    sent = @emails.first
    assert_equal [@current_user.login], sent.to
    assert_equal [@current_user.login], sent.reply_to
    assert_equal [SnsConfig.admin_mail_address], sent.from
    assert_match /#{community.name}/, NKF.nkf("-mJw", sent.subject)
    assert_match /#{reply.content}/, sent.body
    assert_match /[親記事]/, sent.body

    mobile_mail = @emails.second
    assert_equal [@current_user.mobile_email], mobile_mail.to
    assert_equal [@current_user.mobile_email], mobile_mail.reply_to
  end
end

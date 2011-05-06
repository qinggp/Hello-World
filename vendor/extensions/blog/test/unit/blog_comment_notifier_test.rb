require File.dirname(__FILE__) + '/../test_helper'

class BlogCommentNotifierTest < ActionMailer::TestCase
  tests BlogCommentNotifier

  def setup
    setup_emails
  end

  # お知らせメール送信
  def test_notification
    entry = BlogEntry.make
    comment = BlogComment.make(:blog_entry => entry)

    BlogCommentNotifier.deliver_notification(:blog_comment => comment, :blog_entry => entry)
    assert !@emails.empty?

    sent = @emails.first
    assert_equal [entry.user.login], sent.to
    assert_equal [entry.user.login], sent.reply_to
    assert_equal [SnsConfig.admin_mail_address], sent.from
    assert_match /にコメントが/, sent.body

    BlogCommentNotifier.deliver_notification(:blog_comment => comment, :blog_entry => entry, :edited => true)

    sent = @emails.second
    assert_match /修正/, NKF.nkf("-mJw", sent.subject)
    assert_match /のコメント修正が/, sent.body
  end
end

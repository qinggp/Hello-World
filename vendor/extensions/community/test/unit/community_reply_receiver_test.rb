require File.dirname(__FILE__) + '/../test_helper'

# コミュニティスレッドへの返信メール投稿テスト
class CommunityReplyReceiverTest < ActionMailer::TestCase
  tests CommunityReplyReceiver

  def setup
    @real_mobile_email = "SnS_tarou@example.com"
    @user = User.make(:mobile_email => @real_mobile_email)
    @community = set_community_and_has_role(@user)
    @thread = CommunityTopic.make(:community => @community)
    @reply = CommunityReply.make(:community => @community,
                                 :thread => @thread)
  end

  # 返信作成
  def test_receive
    address = CommunityReplyReceiver.mars_receive_address(@user, @thread.id)
    mail = set_mail(address)

    assert_difference "CommunityReply.count" do
      CommunityReplyReceiver.receive(mail)
    end

    reply = CommunityReply.user_id_is(@user.id).first
    assert_equal "作業報告", reply.title
    assert_equal "作業報告\n", reply.content
    assert_equal @community.id, reply.community_id
    assert_equal @thread.id, reply.thread_id
    assert !reply.parent
  end

  # 返信作成（parent_idがあるとき）
  def test_receive_with_parent
    address = CommunityReplyReceiver.mars_receive_address(@user, [@thread.id, @reply.id])
    mail = set_mail(address)

    assert_difference "CommunityReply.count" do
      CommunityReplyReceiver.receive(mail)
    end

    reply = CommunityReply.user_id_is(@user.id).first
    assert_equal "作業報告", reply.title
    assert_equal "作業報告\n", reply.content
    assert_equal @community.id, reply.community_id
    assert_equal @thread.id, reply.thread_id
    assert_equal @reply.id, reply.parent.id
  end

  # 返信作成（添付ファイル付き）
  def test_receive_with_attachments
    address = CommunityReplyReceiver.mars_receive_address(@user, @thread.id)
    mail =
      make_mail_text(:from => @real_mobile_email,
                     :sender => @real_mobile_email,
                     :to => address,
                     :subject => "subject_test",
                     :body => "body_test",
                     :file_paths => [File.join(File.dirname(__FILE__), "../fixtures/files/test.txt"),
                                     File.join(File.dirname(__FILE__), "../fixtures/files/test.gif"),
                                     File.join(File.dirname(__FILE__), "../fixtures/files/test.gif")],
                     :content_types => [["image", "txt"], ["image", "gif"], ["image", "gif"]]
                     )

    assert_difference "CommunityReply.count", 1 do
      assert_difference "CommunityReplyAttachment.count", 3 do
        CommunityReplyReceiver.receive(mail)
      end
    end

    reply = CommunityReply.user_id_is(@user.id).first
    assert_equal "subject_test", reply.title
    assert_equal "body_test\r\n", reply.content
    assert_equal @community.id, reply.community_id

    attachments = reply.attachments.find(:all, :order => "position ASC")
    assert_not_nil attachments[0].image
    assert_equal "test.txt", File.basename(attachments[0].image)
    assert_equal "test.gif", File.basename(attachments[1].image)
    assert_equal "test.gif", File.basename(attachments[2].image)
  end

  # コミュニティトピック作成失敗
  def test_receive_fail
    @user.private_token = "invalid_token"
    address = CommunityReplyReceiver.mars_receive_address(@user, @community.id)
    mail = set_mail(address)

    assert_no_difference "CommunityReply.count" do
      CommunityReplyReceiver.receive(mail)
    end
  end

  # 返信投稿で、複数のアドレスがある場合
  def test_receive_for_multiple_addresses
    addresses = %W(test1@example.com  #{CommunityReplyReceiver.mars_receive_address(@user, @thread.id)} test2@example.com)
    mail = set_mail(addresses)

    assert_difference "CommunityReply.count" do
      CommunityReplyReceiver.receive(mail)
    end

    reply = CommunityReply.user_id_is(@user.id).first
    assert_equal "作業報告", reply.title
    assert_equal "作業報告\n", reply.content
    assert_equal @community.id, reply.community_id
    assert_equal @thread.id, reply.thread_id
    assert !reply.parent
  end

  private

  def set_mail(address)
<<EOF
To: #{Array.wrap(address).join(",")}
From: =?ISO-2022-JP?B?GyRCQ2ZCPBsoQiAbJEJALk1OGyhC?= <#{@real_mobile_email}>
Sender: #{@real_mobile_email}
Subject: =?ISO-2022-JP?B?GyRCOm42SEpzOXAbKEI=?=
Content-Type: text/plain; charset="iso-2022-jp"

=?ISO-2022-JP?B?GyRCOm42SEpzOXAbKEI=?=
EOF
  end
end



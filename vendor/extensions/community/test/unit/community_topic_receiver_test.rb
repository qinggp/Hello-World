require File.dirname(__FILE__) + '/../test_helper'

# コミュニティトピックメール作成テスト
class CommunityTopicReceiverTest < ActionMailer::TestCase
  tests CommunityTopicReceiver

  def setup
    @real_mobile_email = "SnS_tarou@example.com"
    @user = User.make(:mobile_email => @real_mobile_email)
    @community = set_community_and_has_role(@user)
  end

  # コミュニティトピック作成
  def test_receive
    address = CommunityTopicReceiver.mars_receive_address(@user, @community.id)
    mail = set_mail(address)

    assert_difference "CommunityTopic.count", 1 do
      CommunityTopicReceiver.receive(mail)
    end

    topic = CommunityTopic.user_id_is(@user.id).first
    assert_equal "作業報告", topic.title
    assert_equal "作業報告\n", topic.content
    assert_equal @community.id, topic.community_id
  end

  # コミュニティトピック作成（添付ファイル付き）
  def test_receive_with_attachments
    address = CommunityTopicReceiver.mars_receive_address(@user, @community.id)
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

    assert_difference "CommunityTopic.count", 1 do
      assert_difference "CommunityThreadAttachment.count", 3 do
        CommunityTopicReceiver.receive(mail)
      end
    end

    topic = CommunityTopic.user_id_is(@user.id).first
    assert_equal "subject_test", topic.title
    assert_equal "body_test\r\n", topic.content
    assert_equal @community.id, topic.community_id

    attachments = topic.attachments.find(:all, :order => "position ASC")
    assert_not_nil attachments[0].image
    assert_equal "test.txt", File.basename(attachments[0].image)
    assert_equal "test.gif", File.basename(attachments[1].image)
    assert_equal "test.gif", File.basename(attachments[2].image)
  end

  # コミュニティトピック作成失敗
  def test_receive_fail
    @user.private_token = "invalid_token"
    address = CommunityTopicReceiver.mars_receive_address(@user, @community.id)
    mail = set_mail(address)

    assert_no_difference "CommunityTopic.count" do
      CommunityTopicReceiver.receive(mail)
    end
  end

  # トピック投稿で、複数アドレスがあるとき
  def test_receive_for_multiple_addresses
    addresses = %W(test1@example.com  #{CommunityTopicReceiver.mars_receive_address(@user, @community.id)} test2@example.com)

    mail = set_mail(addresses)

    assert_difference "CommunityTopic.count", 1 do
      CommunityTopicReceiver.receive(mail)
    end

    topic = CommunityTopic.user_id_is(@user.id).first
    assert_equal "作業報告", topic.title
    assert_equal "作業報告\n", topic.content
    assert_equal @community.id, topic.community_id
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




require File.dirname(__FILE__) + '/../test_helper'

class MessageAttachmentTest < ActiveSupport::TestCase

  # 添付ファイルを見る権限があるかどうかをテスト
  def test_viewable
    # 関係無い人が作成したメッセージの添付ファイルは見れない
    message = Message.make(:sender => User.make, :receiver => User.make)
    attachment = MessageAttachment.make
    message.attachments << attachment
    assert !attachment.viewable?(User.make)

    # メッセージの送信者であるときは添付ファイルは見れる
    sender = User.make
    message = Message.make(:sender => sender, :receiver => User.make)
    attachment = MessageAttachment.make
    message.attachments << attachment
    assert attachment.viewable?(sender)

    # メッセージの受信者であるときは添付ファイルは見れる
    receiver = User.make
    message = Message.make(:sender => User.make, :receiver => receiver)
    attachment = MessageAttachment.make
    message.attachments << attachment
    assert attachment.viewable?(receiver)
  end
end

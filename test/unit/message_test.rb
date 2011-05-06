require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < ActiveSupport::TestCase

  # メッセージの送信者かどうか返すメソッドのテスト
  def test_sender
    sender = User.make

    message = Message.make(:sender => sender)
    assert message.sender?(sender)
    assert !message.sender?(User.make)
  end

  # メッセージの受信者かどうかを返すメソッドのテスト
  def test_receiver
    receiver = User.make

    message = Message.make(:receiver => receiver)
    assert message.receiver?(receiver)
    assert !message.receiver?(User.make)
  end

  # メッセージが未読かどうかを返すメソッドのテスト
  def test_unread
    assert !Message.make(:unread => false).unread?
    assert Message.make(:unread => true).unread?
  end

  # このメッセージに対して返信を行ったかどうかを返す
  def test_replied
    assert !Message.make(:replied => false).replied?
    assert Message.make(:replied => true).replied?
  end

  # これまで受信したメッセージの送信者を取得する
  def self.sender_to_user
    receiver = User.make
    sender1 = User.make
    sender2 = User.make
    other = user_mkke

    Message.with_options :receiver => receiver do |opt|
      opt.make(:sender => sender1)
      opt.make(:sender => sender1)
      opt.make(:sender => sender2)
    end
    senders = Message.senders_to_user(receiver)

    assert_equal 2, senders.size
    assert senders.include?(sender1)
    assert senders.include?(sender2)
    assert !senders.include?(other)
  end

  # 現在のメールの既読・未読、または返信したかに応じて、表示するメールの画像パスを返すメソッドのテスト
  def test_image_path
    assert_equal "mail_resend.png", Message.make(:replied => true).image_path(User.make)
    assert_equal "mail_close.gif", Message.make(:replied => false, :unread => true).image_path(User.make)
    assert_equal "mail_open.gif", Message.make(:replied => false, :unread => false).image_path(User.make)
  end

  # 受信日時、または送信日時を時系列にみて、1つ前と次のメッセージを取得するメソッドのテスト
  def test_prev_and_next
    receiver = User.make
    sender = User.make

    attributes = {:receiver => receiver, :sender => sender}
    target_message = Message.make(attributes)
    users = [receiver, sender]

    # 前後にメッセージが無い
    users.each do |user|
      assert_nil target_message.prev_and_next(user).first
      assert_nil target_message.prev_and_next(user).second
    end

    # 前にのみメッセージがある
    prev_message = Message.make(attributes)
    prev_message.update_attributes!(:created_at => prev_message.created_at.yesterday)
    users.each do |user|
      assert_equal prev_message.id, target_message.prev_and_next(user).first.id
      assert_nil target_message.prev_and_next(user).second
    end

    # 前後にメッセージがある
    next_message = Message.make(attributes)
    next_message.update_attributes!(:created_at => next_message.created_at.tomorrow)
    users.each do |user|
      assert_equal prev_message.id, target_message.prev_and_next(user).first.id
      assert_equal next_message.id, target_message.prev_and_next(user).second.id
    end
  end

  # 既読処理を行うメソッドのテスト
  def test_read
    sender = User.make
    receiver = User.make

    message = Message.make(:sender => sender,  :receiver => receiver)

    message.read(sender)
    assert message.unread?

    message.read(receiver)
    assert !message.unread?
  end

  # 論理削除を行うメソッドのテスト
  def test_delete_by
    sender = User.make
    receiver = User.make

    message = Message.make(:sender => sender,  :receiver => receiver,
                           :deleted_by_sender => false, :deleted_by_receiver => false)

    assert message.delete_by(sender)
    assert message.deleted_by_sender
    assert !message.deleted_by_receiver

    message = Message.make(:sender => sender,  :receiver => receiver,
                           :deleted_by_sender => false, :deleted_by_receiver => false)

    assert message.delete_by(receiver)
    assert message.deleted_by_receiver
    assert !message.deleted_by_sender
  end

  # メッセージを取り消すメソッドのテスト
  def test_cancel
    sender = User.make
    message = Message.make(:sender => sender)

    assert_difference "Message.count", -1 do
      message.cancel(sender)
    end

    message = Message.make(:sender => sender, :unread => false)
    assert_no_difference "Message.count" do
      message.cancel(sender)
    end

    message = Message.make(:sender => User.make )
    assert_no_difference "Message.count" do
      message.cancel(sender)
    end
  end

  # メッセージが削除可能かどうか判定するメソッドのテスト
  def test_cancelable
    sender = User.make

    message = Message.make(:sender => sender)
    assert message.cancelable?(sender)

    message = Message.make(:sender => sender, :unread => false)
    assert !message.cancelable?(sender)

    message = Message.make(:sender => User.make)
    assert !message.cancelable?(sender)
  end

  # 返信用メッセージの属性値の初期値を決定するメソッドのテスト
  def test_build_reply
    sender = User.make
    received_message = Message.make(:subject => "こんにちは",
                                    :body => "今日はいい天気ですね\n\n眠くなります",
                                    :sender => sender)

    message = Message.new
    message.build_reply(received_message)

    assert_equal message.subject, "Re: こんにちは"
    assert_equal message.body, "> 今日はいい天気ですね\n> \n> 眠くなります"
    assert_equal message.receiver_id, sender.id
  end

  # 削除したメッセージの添付ファイルを参照する他のメッセージが無ければ、添付ファイルが削除される
  def test_destroy_attachments
    attachment = MessageAttachment.make
    messages = Array.new(2) do
      message = Message.make
      message.attachments << attachment
      message
    end

    assert_difference "MessageAttachmentAssociation.count", -1 do
      assert_no_difference "MessageAttachment.count" do
        messages.first.destroy
      end
    end

    assert_difference "MessageAttachmentAssociation.count", -1 do
      assert_no_difference "MessageAttachment.count", -1 do
        messages.second.destroy
      end
    end
  end
end

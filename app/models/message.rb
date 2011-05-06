# == Schema Information
# Schema version: 20100227074439
#
# Table name: messages
#
#  id                  :integer         not null, primary key
#  sender_id           :integer
#  receiver_id         :integer
#  subject             :string(255)
#  body                :text
#  unread              :boolean
#  deleted_by_sender   :boolean
#  deleted_by_receiver :boolean
#  replied             :boolean
#  created_at          :datetime
#  updated_at          :datetime
#

class Message < ActiveRecord::Base
  belongs_to :sender, :foreign_key => "sender_id", :class_name => "User"
  belongs_to :receiver, :foreign_key => "receiver_id", :class_name => "User"
  has_many :message_attachment_associations, :dependent => :destroy
  has_many :attachments, :source => :message_attachment,
           :through => :message_attachment_associations

  accepts_nested_attributes_for :attachments

  after_destroy :destroy_attachments

  named_scope :received_messages_for_user, lambda{ |user|
    cond = ["messages.deleted_by_receiver = ? AND messages.receiver_id = ?",
            false, user.id]
    {:conditions => cond}
  }

  named_scope :sent_messages_for_user, lambda{ |user|
    cond = ["messages.deleted_by_sender = ? AND messages.sender_id = ?",
            false, user.id]
    {:conditions => cond}
  }

  validates_presence_of :subject, :body
  validate :valid_total_filesize_of_attachments?

  @@default_index_order = "messages.created_at DESC"
  cattr_reader :default_index_order

  # メッセージが未読かどうかを返す
  def unread?
    self.unread
  end

  # このメッセージに対して返信を行ったかどうかを返す
  def replied?
    self.replied
  end

  # 現在のメールの既読・未読、または返信したかに応じて、表示するメールの画像パスを返す
  # userとmessageの送信者が同一であれば、送信一覧画面なので返信画像は返さない
  def image_path(user)
    if self.replied? && !self.sender.same_user?(user)
      "mail_resend.png"
    elsif self.unread?
      "mail_close.gif"
    else
      "mail_open.gif"
    end
  end

  # これまで受信したメッセージの送信者を取得する
  def self.senders_to_user(user)
    senders = user.received_messages.map do |message|
      message.sender
    end
    senders.uniq
  end

  # これまで送信したメッセージの受信者を取得する
  def self.receivers_by_user(user)
    receivers = user.sent_messages.map do |message|
      message.receiver
    end
    receivers.uniq
  end

  # メッセージの送信者かどうか
  def sender?(user)
    self.sender.id == user.id
  end

  # メッセージの受信者かどうか
  def receiver?(user)
    self.receiver.id == user.id
  end

  # 受信日時、または送信日時を時系列にみて、1つ前と次のメッセージを取得する。
  # 返り値は配列で、[prev, next]となる。
  def prev_and_next(user)
    if self.receiver?(user)
      messages = Message.received_messages_for_user(user).ascend_by_created_at.all
    elsif self.sender?(user)
      messages = Message.sent_messages_for_user(user).ascend_by_created_at.all
    else
      return false
    end
    pibot = messages.map(&:id).index(self.id)
    next_message = messages[pibot + 1]
    prev_message = (pibot.zero? ? nil : messages[pibot - 1])
    [prev_message, next_message]
  end

  # デフォルト属性値
  def self.default_attributes(attr, sender)
    attr_dup = attr.dup
    attr_dup[:sender_id] = sender.id
    attr_dup[:unread] = true
    attr_dup[:deleted_by_sender] = false
    attr_dup[:deleted_by_receiver] = false
    return attr_dup
  end

  # 件名と本文を元に、複数の宛先へメッセージをコピーして、作成する
  # 添付ファイルも作成するが、各メッセージごとに作成するのではなく、一度実体を作ってあとは中間テーブルを介して関連を持たせる
  # また、メールの作成も行い、全てメッセージが正常に作成されたあとメールの送信を行う
  def copy!(receivers, senderable = true)
    orig_attr = self.attributes.slice("subject", "body")
    mails = []
    receivers.each do |r|
      attr = Message.default_attributes(orig_attr, self.sender).merge(:receiver_id => r.id)
      message = Message.new(attr)
      message.save!
      message.attachments << self.attachments unless self.attachments.blank?

      # 受信側のユーザ設定で、メールの送信を行わない場合はそのユーザには送信しない
      if senderable && r.preference.message_notice_acceptable?
        mails << MessageNotifier.create_notification(message)
      end
    end

    mails.each { |mail| MessageNotifier.deliver(mail) }
  end

  def sorted_attachments
    self.attachments.sort_by{|a| a.position}
  end

  # フォーム添付ファイル生成
  def build_message_attatchments
    3.times do |i|
      attachment = self.attachments.detect{|a| i+1 == a.position}
      if attachment.nil?
        self.attachments.build(:position => i+1)
      end
    end
  end

  # 既読にする。
  # ただし、userが受信したメッセージで、未読である場合に限る
  def read(user)
    return self.update_attributes(:unread => false) if self.receiver?(user) && self.unread
    return true
  end

  # 論理削除する。
  # userが送信者か受信者かによって、どちら側の削除フラグを立てるか決定する
  def delete_by(user)
    if self.receiver?(user)
      return self.update_attributes(:deleted_by_receiver => true)
    elsif self.sender?(user)
      return self.update_attributes(:deleted_by_sender => true)
    end
    return false
  end

  # メッセージの送信を取り消す
  # 取り消し、といっても実際には削除である
  def cancel(user)
    return self.destroy if self.cancelable?(user)
    return nil
  end

  # メッセージの送信を取り消せるかどうか判定する
  def cancelable?(user)
    self.sender?(user) && self.unread?
  end

  # 返信用メッセージの属性値の初期値を決定する
  def build_reply(received_message)
    self.subject = "Re: " + received_message.subject
    self.body = received_message.body.gsub(/^(.*)$/){ "> #{$1}" }
    self.receiver_id = received_message.sender_id
  end

  # ユーザー削除時にそのユーザーに関連するカラムを削除
  def self.destroy_related_to_user_record(user_id)
    messages = self.find(:all, :conditions => ["sender_id = :user_id OR receiver_id = :user_id",{:user_id => user_id}])
    messages.each do |message|
      unless message.attachments.blank?
        MessageAttachment.destroy_related_to_user_record(message.attachments)
      end
      unless message.message_attachment_associations.blank?
        MessageAttachmentAssociation.destroy_related_to_user_record(message.message_attachment_associations)
      end
      #メッセージデータ削除
      message.destroy
    end
  end

  # 標準的なメッセージの件名
  def self.normal_subject(user)
    "#{user.name}さんからメッセージが届いています"
  end

  private
  # 添付ファイルのサイズの合計値を検証
  def valid_total_filesize_of_attachments?
    tolta_size = attachments.inject(0) do |total, a|
      if a.image.blank?
        total
      else
        total += File.size(a.image) unless a.image.blank?
      end
    end
    errors.add(:base, "ファイルの合計サイズが1MBを越えています")  if tolta_size && (tolta_size > 1.megabytes)
  end

  # 削除したメッセージの添付ファイルを参照する他のメッセージが無ければ、添付ファイルを削除する
  def destroy_attachments
    self.attachments.each do |attachment|
      attachment.destroy if attachment.messages.count.zero?
    end
  end
end


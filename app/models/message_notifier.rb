class MessageNotifier < Mars::Iso2022jpMailer
  include Mars::MailSendable

  # メッセージ作成時に同時に送信されるメール
  def notification(message)
    setup_subject!("#{message.sender.name}さんからメッセージが届いています")
    @body["sender"] = message.sender.name
    @body["receiver"] = message.receiver.name
    @body["url"] = message_url(message, :host => CONFIG["host"])

    setup_send_info!(:user => message.receiver)
  end

  # messageモデルの内容そのままに送信されるメール
  # 本文が既にメールの内容と同じ場合等に使用する
  def notification_by_row_message(message)
    setup_subject!(message.subject)
    body message.body
    setup_send_info!(:user => message.receiver)
  end
end

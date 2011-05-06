# メッセージヘルパ
module MessagesHelper

  # 確認画面のForm情報
  def form_params
    if @message.new_record?
      {:url => confirm_before_create_messages_path, :multipart => true,
        :model_instance => @message}
    else
      {:url => confirm_before_update_messages_path(:id => @message.id),
        :multipart => true, :model_instance => @message}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @message.new_record?
      {:url => messages_path, :method => :post,
        :model_instance => @message}
    else
      {:url => message_path(@message), :method => :put,
        :model_instance => @message}
    end
  end

  # 今までメッセージを送信してきたメンバーを選択するselect boxを生成
  def select_sender(user)
    senders = Message.senders_to_user(user)
    list = senders.map {|sender| [sender.name, sender.id] }
    list.unshift ["---", nil]

    select_tag("sender_id", options_for_select(list, params[:sender_id].to_i))
  end

  # 今まで自分のメッセージを受信したことのあるメンバーを選択するselect boxを生成
  def select_receiver(user)
    receivers = Message.receivers_by_user(user)
    list = receivers.map {|receiver| [receiver.name, receiver.id] }
    list.unshift ["---", nil]

    select_tag("receiver_id", options_for_select(list, params[:receiver_id].to_i))
  end

  # 受信メールか送信メールかを返す
  def message_kind(message, user)
    return "受信メール" if message.receiver?(user)
    return "送信メール" if message.sender?(user)
    return ""
  end

  # 受信メールか送信メールかによって、差出人か宛先かを返す
  def sender_or_receiver_label(message, user)
    return "差出人" if message.receiver?(user)
    return "宛先" if message.sender?(user)
    return ""
  end

  # フォーム画面で表示する注意書き
  def form_notation
    notation = font_coution("※") + "は必須項目です。<br />"
    notation += "[ファイル添付のご注意] 添付できるファイルサイズは全て合わせて #{font_coution('1MB')} までです。"
  end

  # 送信メッセージの宛先としてトモダチを一覧表示する
  def friend_address_list(user)
    return "" if user.friends.size.zero?
    column_size = 6
    friends_table = []
    user.friends.each_with_index do |f, i|
      if (i % column_size == 0)
        friends_table << [f]
      else
        friends_table.last << f
      end
    end
    (column_size - friends_table.last.size).times { friends_table.last << "&nbsp" }

    content_tag(:table, :width => "96%") do
      tr = ""
      friends_table.each do |friends|
        tr << content_tag(:tr) do
          td = ""
          friends.each do |friend|
            td << content_tag(:td, :width => "16%", :style => "border: none;") do
              if friend.is_a?(String)
                friend
              else
                check_box_tag("receiver_ids[]", friend.id,
                              params[:receiver_ids].try(:include?, (friend.id.to_s))) +
                  link_to(h(friend.name), user_path(friend))
              end
            end
          end
          td
        end
      end
      tr
    end
  end

  # 確認画面の添付画像表示
  def confirm_attachment_image(form, attachment)
    html = ""
    if attachment.image
      html << theme_image_tag(icon_name_by_extname(attachment.image))
      html << h(File.basename(attachment.image))
    end
    if attachment.new_record?
      html << "<br/>"
      if attachment.image
        if attachment.image =~ Mars::IMAGE_EXT_REGEX
          html << theme_image_tag(show_unpublic_image_temp_messages_path(:image_temp => attachment.image_temp, :image_type => "thumb"))
        end
      else
        html << form.hidden_field(:_delete, :value => "1")
      end
    end
    return html
  end

  # 現在受信メッセージに関するを表示かどうか
  def inbox?
    return true if %w(index search_inbox).include?(action_name)
    return true if action_name == "show" && @message.receiver?(current_user)
    false
  end

  # 現在送信メッセージに関する表示かどうか
  def outbox?
    return true if %w(search_outbox).include?(action_name)
    return true if action_name == "show" && @message.sender?(current_user)
    false
  end

  # メッセージの送信関連の画面が、個別送信かどうか
  def sending_individually?
    !params[:individually].blank?
  end
end

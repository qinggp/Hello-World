# メッセージを作成するモジュール
#
module Mars::Messageable
  # メッセージの作成、本文メール送信
  def self.send_row_message!(attrs)
    message = Message.new(Message.default_attributes(attrs, attrs[:sender]))
    message.save!
    MessageNotifier.deliver_notification_by_row_message(message)
  end

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.send(:helper, Mars::Messageable::Helper)
  end

  module InstanceMethods
    # メッセージ作成フォーム表示アクション
    #
    # ==== 引数
    #
    # * params[:receiver_ids] - 受信者のIDの配列
    def new_message
      @message ||= Message.new

      render_form_for_message
    end

    # メッセージ作成内容確認アクション
    #
    # === 引数
    #
    # * params[:receiver_ids] - 受信者のIDの配列
    def confirm_before_create_message
      @message = Message.new(Message.default_attributes(params[:message], current_user))

      if params[:clear]
        return response_for_confirm_before_create_message_at_clear
      end

      # 全員に送信するにチェックが入っているとき
      unless params[:all_receivers].blank?
        params[:receiver_ids] = params[:all_receiver_ids]
      end

      # 宛先の情報が渡ってきてないとき
      if params[:receiver_ids].blank?
        @message.errors.add(:sender_id, "を入力して下さい")
        render_form_for_message
        return
      end

      @receivers = User.find(params[:receiver_ids])

      if @message.valid?
        set_unpublic_image_uploader_keys_for_message(@message)
        render "message_confirm"
      else
        render_form_for_message
      end
    end

    # メッセージ作成アクション
    #
    # === 引数
    #
    # * params[:receiver_ids] - 受信者のIDの配列
    # * params[:message_notice] - メッセージ通知メールを送信するかどうか
    def create_message
      @message =
        Message.new(Message.default_attributes(params[:message], current_user))

      return render_form_for_message if params[:cancel] || !@message.valid?
      receivers = User.find(params[:receiver_ids])

      # フォームから入力された内容に対して、本文を加工する
      decorate(@message)

      # メッセージが届いたことそのものを知らせる通知メールを送信するかどうか
      # 作成した内容自体は反映されない
      message_notice = params[:message_notice].blank? ? false : true
      Message.transaction do
        @message.copy!(receivers, message_notice)
      end

      # 各メッセージ内容に応じたメール送信
      # 通知メールを送信している場合は、ここは送信しない
      send_mail(@message, receivers) unless message_notice

      clear_unpublic_image_uploader_key if respond_to?(:clear_unpublic_image_uploader_key)
      response_for_create_message
    end

    # メッセージ作成完了アクション
    def complete_after_create_message
      @message = "送信完了いたしました。"
      @back_link_template = "back_message"
      render "/share/complete", :layout => "application"
    end

    private

    def render_form_for_message
      unless params[:receiver_ids].blank?
        @receivers = User.find(params[:receiver_ids])
      end
      @message.build_message_attatchments
      render "message_form"
    end

    # メッセージの添付ファイルアップロードキー設定
    def set_unpublic_image_uploader_keys_for_message(message)
      message.attachments.each do |at|
        self.unpublic_image_uploader_key = at.image_temp unless at.image_temp.blank?
      end
    end

    # フォームから入力された内容で作成されたメッセージを必要であればさらに加工する
    def decorate(message)
    end

    # 作成したメッセージを元に、メールを送信する
    # 継承したコントローラで適切処理に変える必要がある
    def send_mail(message, receivers)
      receivers.each do |r|
        MessageNotifier.deliver_notification(message)
      end
    end

    # フォームで入力した内容をクリアしたときのレスポンス
    # 必要であれば、継承したコントローラで書き換える
    def response_for_confirm_before_create_message_at_clear
      redirect_to :action => :new_message, :id => params[:id], :receiver_ids => params[:receiver_ids]
    end

    # メッセージ作成後のレスポンス
    # 必要であれば、継承したコントローラで書き換える
    def response_for_create_message
      redirect_to :action => :complete_after_create_message
    end
  end

  module Helper
    # メッセージ作成確認画面で添付ファイル（一時ファイル）を表示するヘルパー
    def confirm_message_attachment_image(form, attachment)
      html = ""
      if attachment.image
        html << theme_image_tag(icon_name_by_extname(attachment.image))
        html << h(File.basename(attachment.image))
      end
      if attachment.new_record?
        html << "<br/>"
        if attachment.image
          if attachment.image =~ Mars::IMAGE_EXT_REGEX
            html << theme_image_tag(url_for(:action => :show_unpublic_image_temp, :image_temp => attachment.image_temp, :image_type => "thumb"))
          end
        else
          html << form.hidden_field(:_delete, :value => "1")
        end
      end
      return html
    end

    # メッセージ作成確認画面のForm情報
    def message_form_params
      {:model_instance => @message,
        :url =>{:action => :confirm_before_create_message},
        :html => {:method => :post},
        :multipart => true}
    end

    # メッセージ作成のForm情報
    def message_confirm_params
      {:model_instance => @message,
        :url => {:action => :create_message},
        :html => {:method => :post}}
    end

    # メッセージの宛先を選択するチェックボックスの生成
    #
    # ==== 引数
    #
    # * receivers - 受信者(Userオブジェクト）の配列
    def check_box_for_receivers(receivers)
      html = check_box_tag("all_receivers", "yes", params[:all_check]) + "全員" + "<br />"
      receivers.in_groups_of(3).each do |rs|
        rs.each do |r|
          break unless r
          html << hidden_field_tag("all_receiver_ids[]", r.id)
          html << check_box_tag("receiver_ids[]", r.id,
                                params[:receiver_ids].try(:include?, r.id.to_s))
          html << h(r.name) + "&nbsp;"
        end
        html << "<br />"
      end
      html
    end
  end
end

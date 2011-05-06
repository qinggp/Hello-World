# メッセージ管理
class MessagesController < ApplicationController
  include Mars::UnpublicImageAccessible

  unpublic_image_accessible :model_name => :message_attachment

  access_control do
    allow logged_in
  end

  with_options :redirect_to => :messages_url do |con|
    con.verify :params => "id", :only => %w(show destroy)
    con.verify :params => "message",
      :only => %w(confirm_before_create create)
    con.verify :method => :post, :only => %w(confirm_before_create)
    con.verify :method => :put, :only => %w(delete)
    con.verify :method => :delete, :only => %w(destroy)
  end

  before_filter :load_message, :only => %w(show delete destroy confirm_before_delete)

  # メッセージの送信者、あるいは受信者であるかどうかで操作権限をチェックする
  before_filter :check_sender_or_receiver_accessible, :only => %w(show delete confirm_before_delete)
  before_filter :check_sender_accessible, :only => :destroy

  # 添付画像を閲覧する権限があるかチェックする
  before_filter :check_viewable_attachment, :only => :show_unpublic_image

  # 受信メッセージ一覧を表示する
  def index
    get_received_messages
  end

  # 検索パラメータを受け取って受信ボックスの中のメッセージを表示する
  # また、チェックされたメッセージを一括削除、一括既読も行う
  def search_inbox
    if params[:delete]
      Message.update_all(["deleted_by_receiver = ?", true],
                         ["id IN (?) AND receiver_id = ?", params[:receiver_ids], current_user.id])
      return redirect_to messages_path
    end

    if params[:read]
      Message.update_all(["unread = ?", false],
                         ["id IN (?) AND receiver_id = ?", params[:receiver_ids], current_user.id])
    end

    get_received_messages
    render "index"
  end

  # 検索パラメータを受け取って受信ボックスの中のメッセージを表示する
  # また、チェックされたメッセージの一括削除を行う
  def search_outbox
    if params[:delete]
      Message.update_all(["deleted_by_sender = ?", true],
                         ["id IN (?) AND sender_id = ?", params[:receiver_ids], current_user.id])
      return redirect_to search_outbox_messages_path
    end

    get_sent_messages
  end

  # メッセージ詳細画面
  def show
    @prev_message, @next_message = @message.prev_and_next(current_user)
    if @message.sender?(current_user)
      @message_receiver_or_sender = @message.receiver
    elsif @message.receiver?(current_user)
      @message_receiver_or_sender = @message.sender
    end

    flash[:error] = "既読処理に失敗しました" unless @message.read(current_user)
  end

  # 登録フォームの表示．
  def new
    @message ||= Message.new

    if !params[:received_message_id].blank? && Message.exists?(params[:received_message_id])
      # 返信時
      received_message = Message.find(params[:received_message_id])
      @message.build_reply(received_message)
    elsif params[:individually]
      # 個別へのメッセージ送信時
      @message.receiver_id = params[:receiver_id]
    end

    render_form
  end

  # 登録確認画面表示
  def confirm_before_create
    @message =
      Message.new(Message.default_attributes(params[:message], current_user))

    if params[:clear]
      if params[:individually]
        return redirect_to new_message_path(:received_message_id => params[:received_message_id],
                                            :individually => 1,
                                            :receiver_id => @message.receiver_id)
      else
        return redirect_to new_message_path
      end
    end

    # 宛先の情報が渡ってきてないとき
    if params[:receiver_ids].blank?
      @message.errors.add(:base, "宛先を入力して下さい")
      render_form
      return
    end

    @receivers = User.find(params[:receiver_ids])

    if @message.valid?
      set_unpublic_image_uploader_keys(@message)
      render "confirm"
    else
      render_form
    end
  end

  # 登録データをDBに保存．
  def create
    @message =
      Message.new(Message.default_attributes(params[:message], current_user))

    return render_form if params[:cancel] || !@message.valid?
    receivers = User.find(params[:receiver_ids])

    Message.transaction do
      # 返信メッセージであるとき、そのメッセージの返信フラグをtrueにする
      if !params[:received_message_id].blank? && Message.exists?(params[:received_message_id])
        received_message = Message.find(params[:received_message_id])
        received_message.update_attributes!(:replied => true)
      end
      @message.copy!(receivers)
    end

    clear_unpublic_image_uploader_key
    redirect_to complete_after_create_messages_path
  end

  # メッセージの送信を取り消す
  def destroy
    flash[:error] = "メッセージの取り消しに失敗しました" unless @message.cancel(current_user)

    redirect_to messages_path
  end

  # 送信側、または受信側でメッセージの削除
  # 実際にはフラグをたてる論理削除
  def delete
    if @message.sender?(current_user)
      redirect_to search_outbox_messages_path
    else
      redirect_to messages_path
    end
    flash[:error] = "削除に失敗しました" unless @message.delete_by(current_user)
  end

  # メッセージの論理削除確認画面
  # 携帯用
  def confirm_before_delete
    render "confirm_before_delete"
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    messages_path
  end

  private
  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :per_page => (params[:per_page] ? sanitize_sql(params[:per_page]) : 20),
      :order => (params[:order] ? construct_sort_order : Message.default_index_order),
    }
  end

  # 受信メッセージを取得する
  def get_received_messages
    @messages = Message.received_messages_for_user(current_user)
    scope_by_unread
    scope_by_sender
    scope_by_keyword

    if all_pages?
      @messages =
        @messages.all(:order => paginate_options[:order], :include => :sender)
    else
      @messages =
        @messages.paginate(paginate_options.merge(:include => :sender))
    end
  end

  # 送信メッセージを取得する
  def get_sent_messages
    @messages = Message.sent_messages_for_user(current_user)

    scope_by_unread
    scope_by_receiver
    scope_by_keyword

    if all_pages?
      @messages =
        @messages.all(:order => paginate_options[:order], :include => :receiver)
    else
      @messages =
        @messages.paginate(paginate_options.merge(:include => :receiver))
    end
  end

  # 未読のみで絞り込み
  def scope_by_unread
    @messages = @messages.unread_is(true) unless params[:unread].blank?
  end

  # 送信者で絞り込み
  def scope_by_sender
    @messages = @messages.sender_id_is(params[:sender_id]) unless params[:sender_id].blank?
  end

  # 受信者で絞り込み
  def scope_by_receiver
    @messages = @messages.receiver_id_is(params[:receiver_id]) unless params[:receiver_id].blank?
  end

  # キーワードで絞り込み
  def scope_by_keyword
    @messages = @messages.subject_or_body_like(params[:keyword]) unless params[:keyword].blank?
  end

  def load_message
    if params[:id] && Message.exists?(params[:id])
      @message = Message.find(params[:id])
    end
  end

  # ファイルアップロードキー設定
  def set_unpublic_image_uploader_keys(message)
    message.attachments.each do |at|
      self.unpublic_image_uploader_key = at.image_temp unless at.image_temp.blank?
    end
  end

  def render_form
    @message.build_message_attatchments
    render "form"
  end

  # メッセージの受信者、または送信者であるかチェック
  def check_sender_or_receiver_accessible
    if !@message.sender?(current_user) && !@message.receiver?(current_user)

      flash[:error] = "メッセージを操作する権限がありません"
      redirect_to messages_path
      return false
    end
  end

  # メッセージの送信者であるかチェック
  def check_sender_accessible
    if !@message.sender?(current_user)
      flash[:error] = "メッセージを操作する権限がありません"
      redirect_to messages_path
      return false
    end
  end

  # 添付ファイルを閲覧できるかチェック
  def check_viewable_attachment
    if params[:message_attachment_id] && MessageAttachment.find(params[:message_attachment_id])
      attachment = MessageAttachment.find(params[:message_attachment_id])
      if !attachment.viewable?(current_user)
        flash[:error] = "ファイルを閲覧する権限がありません"
        redirect_to messages_path
        return false
      end
    end
  end
end

require File.dirname(__FILE__) + '/../test_helper'

# メッセージ管理テスト
class MessagesControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
    setup_emails
  end

  # 一覧画面の表示
  def test_index
    get :index

    assert_response :success
    assert_template 'messages/index'
    assert_not_nil assigns(:messages)
  end

  # 未読のみで、受信メッセージを検索
  def test_search_inbox_by_unread
    set_messages_for_search_inbox

    get :search_inbox, :unread => true

    assert_equal 15, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'
  end

  # 送信者で、受信メッセージを検索
  def test_search_inbox_by_sender
    sender = User.make
    set_messages_for_search_inbox(:sender => sender)

    get :search_inbox, :sender_id => sender.id
    assert_equal 15, assigns(:messages).count

    get :search_inbox, :sender_id => User.make.id
    assert_equal 0, assigns(:messages).count

    assert_response :success
    assert_template 'messages/index'
  end

  # 未読のみで、かつ送信者で受信メッセージを検索
  def test_search_inbox_by_unread_and_sender
    sender = User.make
    set_messages_for_search_inbox(:sender => sender)

    get :search_inbox, :sender_id => sender.id, :unread => true

    assert_equal 10, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'
  end

  # キーワードで受信メッセージを検索
  def test_search_inbox_by_keyword
    set_messages_for_search_inbox

    get :search_inbox, :keyword => "test test"
    assert_equal 0, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'

    get :search_inbox, :keyword => "タイトル"
    assert_equal 15, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'

    get :search_inbox, :keyword => "本文"
    assert_equal 15, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'

    get :search_inbox, :keyword => "test"
    assert_equal 5, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'
  end

  # キーワードと送信者で受信メッセージを検索
  def test_search_inbox_by_keyword_and_sender
    sender = User.make
    set_messages_for_search_inbox(:sender => sender)

    get :search_inbox, :keyword => "test test", :sender_id => sender.id
    assert_equal 0, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'

    get :search_inbox, :keyword => "タイトル", :sender_id => User.make.id
    assert_equal 0, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'

    get :search_inbox, :keyword => "タイトル", :sender_id => sender.id
    assert_equal 10, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'

    get :search_inbox, :keyword => "test", :sender_id => sender.id
    assert_equal 5, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'
  end

  # キーワードと未読のみで受信メッセージを検索
  def test_search_inbox_by_keyword_and_unread
    set_messages_for_search_inbox

    get :search_inbox, :keyword => "test test", :unread => true
    assert_equal 0, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'

    get :search_inbox, :keyword => "本文", :unread => true
    assert_equal 10, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'
  end

  # キーワード、未読のみ、送信者で受信メッセージを検索
  def test_search_inbox_by_keyword_unread_and_sender
    sender = User.make
    set_messages_for_search_inbox(:sender => sender)

    get :search_inbox, :keyword => "test test", :unread => true, :sender_id => sender.id
    assert_equal 0, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'

    get :search_inbox, :keyword => "本文", :unread => true, :sender_id => User.make.id
    assert_equal 0, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'

    get :search_inbox, :keyword => "本文", :unread => true, :sender_id => sender.id
    assert_equal 5, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'

    get :search_inbox, :keyword => "test", :unread => true, :sender_id => sender.id
    assert_equal 5, assigns(:messages).count
    assert_response :success
    assert_template 'messages/index'
  end

  # 登録画面の表示
  def test_new
    get :new

    assert_response :success
    assert_template 'messages/form'
    assert_kind_of Message, assigns(:message)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    assert_no_difference(['Message.count']) do
      post :confirm_before_create, :message => Message.plan,
           :receiver_ids => [User.make.id]
    end

    assert_response :success
    assert_template 'messages/confirm'
    assert_equal true, assigns(:message).valid?
  end

  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    assert_no_difference(['Message.count']) do
      post :confirm_before_create, :message => Message.plan(:body => ""),
           :receiver_ids => [User.make.id]
    end

    assert_response :success
    assert_template 'messages/form'
    assert_equal false, assigns(:message).valid?
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    post :confirm_before_create, :message => {}, :clear => "Clear"

    assert_response :redirect
    assert_redirected_to new_message_path
  end

  # 登録データの作成
  def test_create_message
    receivers = [User.make, User.make]

    assert_difference(['Message.count'], 2) do
      post :create, :message => Message.plan, :receiver_ids => receivers
    end

    assert_equal 1, receivers.first.received_messages.size
    message = receivers.first.received_messages.first

    [:body, :subject].each do |attr|
      assert_equal Message.plan[attr], message.send(attr)
    end
    assert_equal @current_user.id, message.sender_id

    assert_equal 2, @emails.size

    assert_redirected_to complete_after_create_messages_path
  end

  # 登録データの作成を行うが、送信先のユーザがメールの受信を行わない設定のときはメールが送信されない
  def test_create_message_not_send_mail
    receivers = Array.new(2) do
      preference = Preference.make(:message_notice_acceptable => false)
      User.make(:preference => preference)
    end

    assert_difference(['Message.count'], 2) do
      post :create, :message => Message.plan, :receiver_ids => receivers
    end

    assert_equal 0, @emails.size
    assert_redirected_to complete_after_create_messages_path
  end


  # 登録データの作成キャンセル
  def test_create_message_cancel
    assert_no_difference(['Message.count']) do
      post :create, :message => Message.plan, :cancel => "Cancel"
    end

    assert_not_nil assigns(:message)
    assert_template 'messages/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_message_fail
    assert_no_difference(['Message.count']) do
     post :confirm_before_create, :message => Message.plan(:body => ""),
          :receiver_ids => [User.make.id]
    end

    assert_template 'messages/form'
  end

  # 詳細画面の表示
  def test_show_message
    get :show, :id => Message.make(:receiver => @current_user).id

    assert_response :success
    assert_template 'messages/show'
    assert_kind_of Message, assigns(:message)
  end

  # レコードの削除
  def test_destroy_message
    message = Message.make(:sender => @current_user)

    assert_difference('Message.count', -1) do
      delete :destroy, :id => message.id
    end

    assert_redirected_to messages_path
  end

  # 送信者がメッセージを論理削除
  def test_delete_by_sender
    message = Message.make(:sender => @current_user)

    put :delete, :id => message.id

    message.reload
    assert message.deleted_by_sender
    assert_response :redirect
    assert_redirected_to search_outbox_messages_path
  end

  # 受信者がメッセージを論理削除
  def test_delete_by_receiver
    message = Message.make(:receiver => @current_user)

    put :delete, :id => message.id

    message.reload
    assert message.deleted_by_receiver
    assert_response :redirect
    assert_redirected_to messages_path
  end

  # メッセージ返信画面
  def test_new_for_reply
    received_message = Message.make(:receiver => @current_user)

    get :new, :individually => 1, :received_message_id => received_message.id

    assert_response :success
    assert_template 'messages/form'
    assert_kind_of Message, assigns(:message)
  end

  # メッセージ返信内容確認画面
  def test_confirm_before_create_for_reply
    received_message = Message.make(:receiver => @current_user)

    assert_no_difference(['Message.count']) do
      post :confirm_before_create, :message => Message.plan,
           :individually => 1, :received_message_id => received_message.id,
           :receiver_ids => [User.make.id]
    end

    assert_response :success
    assert_template 'messages/confirm'
    assert_equal true, assigns(:message).valid?
  end


  # メッセージ返信内容確認画面表示失敗
  def test_confirm_before_create_fail_for_reply
    received_message = Message.make(:receiver => @current_user)

    assert_no_difference(['Message.count']) do
      post :confirm_before_create, :message => Message.plan(:body => ""),
           :individually => 1, :received_message_id => received_message.id,
           :receiver_ids => [User.make.id]
    end

    assert_response :success
    assert_template 'messages/form'
    assert_equal false, assigns(:message).valid?
  end

  # メッセージ返信入力情報クリア（登録時）
  def test_confirm_before_create_clear_for_reply
    received_message = Message.make(:receiver => @current_user)

    post :confirm_before_create, :message => {}, :clear => "Clear",
         :individually => 1, :received_message_id => received_message.id

    assert_response :redirect
    assert_redirected_to new_message_path(:individually => 1, :received_message_id => received_message.id)
  end

  # メッセージ返信データの作成
  def test_create_message_for_reply
    received_message = Message.make(:receiver => @current_user)

    receivers = [received_message.sender]

    assert_difference 'Message.count' do
      post :create, :message => Message.plan, :receiver_ids => receivers,
           :individually => 1, :received_message_id => received_message.id
    end

    assert_equal 1, receivers.first.received_messages.size
    message = receivers.first.received_messages.first

    [:body, :subject].each do |attr|
      assert_equal Message.plan[attr], message.send(attr)
    end

    received_message.reload
    assert received_message.replied

    assert_equal @current_user.id, message.sender_id

    assert_equal 1, @emails.size

    assert_redirected_to complete_after_create_messages_path
  end

  # メッセージ返信データの作成を行うが、返信先のユーザがメールの受信を行わない設定のときはメールが送信されない
  def test_create_message_for_reply_not_send_mail
    sender = User.make(:preference => Preference.make(:message_notice_acceptable => false))
    received_message = Message.make(:receiver => @current_user, :sender => sender)
    receivers = [received_message.sender]

    assert_difference 'Message.count' do
      post :create, :message => Message.plan, :receiver_ids => receivers,
           :individually => 1, :received_message_id => received_message.id
    end

    assert_equal 0, @emails.size

    assert_redirected_to complete_after_create_messages_path
  end


  # 返信メッセージの作成キャンセル
  def test_create_message_cancel_for_reply
    received_message = Message.make(:receiver => @current_user)

    assert_no_difference(['Message.count']) do
      post :create, :message => Message.plan, :cancel => "Cancel",
           :individually => 1, :received_message_id => received_message.id
    end

    assert_not_nil assigns(:message)
    assert_template 'messages/form'
  end

  # 返信メッセージ作成の失敗（バリデーション）
  def test_create_message_fail_for_reply
    received_message = Message.make(:receiver => @current_user)

    assert_no_difference(['Message.count']) do
     post :confirm_before_create, :message => Message.plan(:body => ""),
          :receiver_ids => [User.make.id],
          :individually => 1, :received_message_id => received_message.id
    end

    assert_template 'messages/form'
  end

  # 単一メッセージ送信画面
  def test_new_for_individually
    receiver = User.make

    get :new, :individually => 1, :receiver_id => receiver.id

    assert_response :success
    assert_template 'messages/form'
    assert_kind_of Message, assigns(:message)
  end

  # 単一メッセージ送信内容確認画面
  def test_confirm_before_create_for_individually
    assert_no_difference(['Message.count']) do
      post :confirm_before_create, :message => Message.plan,
           :individually => 1, :receiver_ids => [User.make.id]
    end

    assert_response :success
    assert_template 'messages/confirm'
    assert_equal true, assigns(:message).valid?
  end

  # 単一メッセージ送信内容確認画面表示失敗
  def test_confirm_before_create_fail_for_individually
    assert_no_difference(['Message.count']) do
      post :confirm_before_create, :message => Message.plan(:body => ""),
           :individually => 1, :receiver_ids => [User.make.id]
    end

    assert_response :success
    assert_template 'messages/form'
    assert_equal false, assigns(:message).valid?
  end

  # 単一メッセージ送信入力情報クリア（登録時）
  def test_confirm_before_create_clear_for_individually
    post :confirm_before_create, :message => {}, :clear => "Clear",
         :individually => 1

    assert_response :redirect
    assert_redirected_to new_message_path(:individually => 1)
  end

  # 単一メッセージ送信データの作成
  def test_create_message_for_individually
    receiver = User.make

    assert_difference 'Message.count' do
      post :create, :message => Message.plan, :receiver_ids => [receiver.id],
           :individually => 1
    end

    receiver.reload
    assert_equal 1, receiver.received_messages.size
    message = receiver.received_messages.first

    [:body, :subject].each do |attr|
      assert_equal Message.plan[attr], message.send(attr)
    end

    assert_equal @current_user.id, message.sender_id

    assert_equal 1, @emails.size

    assert_redirected_to complete_after_create_messages_path
  end

  # 単一メッセージ送信データの作成を行うが、送信先のユーザがメールの受信を行わない設定のときはメールが送信されない
  def test_create_message_for_individually_not_send_mail
    receiver = User.make(:preference => Preference.make(:message_notice_acceptable => false))

    assert_difference 'Message.count' do
      post :create, :message => Message.plan, :receiver_ids => [receiver.id],
           :individually => 1
    end

    assert_equal 0, @emails.size

    assert_redirected_to complete_after_create_messages_path
  end


  # 単一メッセージの作成キャンセル
  def test_create_message_cancel_for_individually
    assert_no_difference(['Message.count']) do
      post :create, :message => Message.plan, :cancel => "Cancel",
           :individually => 1
    end

    assert_not_nil assigns(:message)
    assert_template 'messages/form'
  end

  # 単一メッセージ作成の失敗（バリデーション）
  def test_create_message_fail_for_individually
    assert_no_difference(['Message.count']) do
     post :confirm_before_create, :message => Message.plan(:body => ""),
          :receiver_ids => [User.make.id], :individually => 1
    end

    assert_template 'messages/form'
  end

  # 非ログイン状態ではアクセス拒否される
  def test_access_deny_without_login
    logout

    assert_raise Acl9::AccessDenied do
      get :index
    end
  end

  # メッセージの送信者、または受信者でなければメッセージは見れない
  def test_deny_access_to_show
    message = Message.make

    get :show, :id => message.id

    assert_equal "メッセージを操作する権限がありません", flash[:error]
    assert_response :redirect
    assert_redirected_to messages_path
  end

  # メッセージの送信者、または受信者でなければメッセージの論理削除ができない
  def test_deny_access_to_delete
    message = Message.make

    put :delete, :id => message.id

    assert_equal "メッセージを操作する権限がありません", flash[:error]
    assert_response :redirect
    assert_redirected_to messages_path

    set_mobile_user_agent

    put :confirm_before_delete, :id => message.id
    assert_equal "メッセージを操作する権限がありません", flash[:error]
    assert_response :redirect
    assert_redirected_to messages_path
  end

  # メッセージの送信者でなければ、メッセージの取り消しができない
  def test_deny_access_to_destroy
    message = Message.make(:receiver => @current_user)

    delete :destroy, :id => message.id

    assert_equal "メッセージを操作する権限がありません", flash[:error]
    assert_response :redirect
    assert_redirected_to messages_path
  end

  # 添付ファイルへアクセスできる
  def test_show_unpublic_image
    message = Message.make(:sender => @current_user,
                           :receiver => User.make)
    attachment = MessageAttachment.make
    message.attachments << attachment

    get :show_unpublic_image, :message_attachment_id => attachment.id

    assert_response :success
  end

  # メッセージの送信者や受信者が無いとき、添付ファイルへアクセスできない
  def test_deny_access_to_show_unpublic_image
    message = Message.make
    attachment = MessageAttachment.make
    message.attachments << attachment

    get :show_unpublic_image, :message_attachment_id => attachment.id

    assert_response :redirect
    assert_redirected_to messages_path
  end

  private

  # 受信箱の中身を検索するテストの際に用いるデータのセット
  def set_messages_for_search_inbox(options={ })
    Message.destroy_all
    sender = options[:sender] || User.make
    receiver = options[:receiver] || @current_user

    # senderからreceiverへ5件のメッセージ
    5.times { Message.make(:sender => sender, :receiver => receiver) }

    # senderからreceiverへ5件のメッセージ。ただし、既読
    5.times { Message.make(:sender => sender, :receiver => receiver, :unread => false) }

    # senderからreceiverへ5件のメッセージ。ただし、receiverからは削除
    5.times { Message.make(:sender => sender, :receiver => receiver, :deleted_by_receiver => true) }

    # sender以外から、receiverへ5件のメッセージ。
    5.times { Message.make(:sender => User.make, :receiver => receiver) }

    # senderからreceiverへ5件のメッセージ。ただし、本文と、タイトルは変えてある
    5.times { Message.make(:sender => sender, :receiver => receiver,
                           :subject => "test subject", :body => "test body") }
  end
end

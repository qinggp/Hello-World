require File.dirname(__FILE__) + '/../test_helper'

# コミュニティメンバーメッセージ管理機能テスト
class CommunityMemberMessagesControllerTest < ActionController::TestCase

  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # コミュニティイベント参加者へのメッセージ入力画面
  def test_new_event_message
    event = set_community_event_and_members(User.make)

    get :new_message, :event_id => event.id, :id => event.community_id

    assert_response :success
    assert_template "community_member_messages/message_form"
  end

  # コミュニティイベント参加者へのメッセージ作成確認画面
  def test_confirm_before_create_event_message
    member = User.make
    event = set_community_event_and_members(member)

    get :confirm_before_create_message, :event_id => event.id, :id => event.community_id,
        :receiver_ids => [member.id.to_s],
        :message => {:subject => "subject", :body => "body"}

    message = assigns(:message)

    assert_equal "body", message.body
    assert_equal "subject", message.subject

    assert_response :success
    assert_template "community_member_messages/message_confirm"
  end

  # コミュニティイベント参加者へのメッセージ作成確認画面失敗
  def test_confirm_before_create_event_message_fail
    member = User.make
    event = set_community_event_and_members(member)

    get :confirm_before_create_message, :event_id => event.id, :id => event.community_id,
        :receiver_ids => [member.id.to_s],
        :message => {:subject => "subject", :body => ""}

    message = assigns(:message)

    assert !message.valid?

    assert_response :success
    assert_template "community_member_messages/message_form"
  end

  # コミュニティイベント参加者へのメッセージ入力クリア
  def test_confirm_before_create_event_message_clear
    member = User.make
    event = set_community_event_and_members(member)

    get :confirm_before_create_message, :event_id => event.id, :id => event.community_id,
        :receiver_ids => [member.id.to_s],
        :message => {:subject => "subject", :body => ""},
        :clear => 'Clear'

    message = assigns(:message)

    assert_response :redirect
    assert_redirected_to new_message_community_member_message_path(:event_id => event.id, :id => event.community_id, :receiver_ids => [member.id])
  end

  # コミュニティイベント参加者へのメッセージ作成
  def test_create_event_message
    number_of_members = 2
    members = Array.new(number_of_members) { User.make }
    event = set_community_event_and_members(members)

    assert_difference("Message.count", number_of_members) do
      get :create_message, :event_id => event.id, :id => event.community_id,
          :receiver_ids => [members.map(&:id)],
          :message => {:subject => "subject", :body => "body"}
    end

    members.each do |member|
      message = Message.sender_id_is(@current_user.id).receiver_id_is(member.id).first
      assert_equal "subject", message.subject
      assert_match /body/, message.body
    end

    assert_response :redirect
    assert_redirected_to complete_after_create_message_community_member_message_path(:event_id => event.id, :id => event.community_id)
  end

  # コミュニティイベント参加者へのメッセージ作成キャンセル
  def test_create_event_message_cancel
    member = User.make
    event = set_community_event_and_members(member)

    assert_no_difference("Message.count") do
      get :create_message, :event_id => event.id, :id => event.community_id,
          :receiver_ids => [member.id.to_s],
          :message => {:subject => "subject", :body => "body"},
          :cancel => 'Cancel'
    end

    assert_response :success
    assert_template "community_member_messages/message_form"
  end

  # コミュニティイベント参加者へのメッセージ作成失敗
  def test_create_event_message_fail
    member = User.make
    event = set_community_event_and_members(member)

    assert_no_difference("Message.count") do
      get :create_message, :event_id => event.id, :id => event.community_id,
          :receiver_ids => [member.id.to_s],
          :message => {:subject => "subject", :body => ""},
          :cancel => 'Cancel'
    end

    assert !assigns(:message).valid?

    assert_response :success
    assert_template "community_member_messages/message_form"
  end

  # コミュニティメンバーへのメッセージ入力画面
  def test_new_message
    community = set_community_and_members(User.make)

    get :new_message, :id => community.id

    assert_response :success
    assert_template "community_member_messages/message_form"
  end

  # コミュニティメンバーへのメッセージ作成確認画面
  def test_confirm_before_create_message
    member = User.make
    community = set_community_and_members(member)

    get :confirm_before_create_message, :id => community.id,
        :receiver_ids => [member.id.to_s],
        :message => {:subject => "subject", :body => "body"}

    message = assigns(:message)

    assert_equal "body", message.body
    assert_equal "subject", message.subject

    assert_response :success
    assert_template "community_member_messages/message_confirm"
  end

  # コミュニティメンバーへのメッセージ作成確認画面失敗
  def test_confirm_before_create_message_fail
    member = User.make
    community = set_community_and_members(member)

    get :confirm_before_create_message, :id => community.id,
        :receiver_ids => [member.id.to_s],
        :message => {:subject => "subject", :body => ""}

    message = assigns(:message)

    assert !message.valid?

    assert_response :success
    assert_template "community_member_messages/message_form"
  end

  # コミュニティメンバーへのメッセージ入力クリア
  def test_confirm_before_create_message_clear
    member = User.make
    community = set_community_and_members(member)

    get :confirm_before_create_message, :id => community.id,
        :receiver_ids => [member.id.to_s],
        :message => {:subject => "subject", :body => ""},
        :clear => 'Clear'

    message = assigns(:message)

    assert_response :redirect
    assert_redirected_to new_message_community_member_message_path(:id => community.id, :receiver_ids => [member.id])
  end

  # コミュニティメンバーへのメッセージ作成
  def test_create_message
    number_of_members = 2
    members = Array.new(number_of_members) { User.make }
    community = set_community_and_members(members)

    assert_difference("Message.count", number_of_members) do
      get :create_message, :id => community.id,
          :receiver_ids => [members.map(&:id)],
          :message => {:subject => "subject", :body => "body"}
    end

    members.each do |member|
      message = Message.sender_id_is(@current_user.id).receiver_id_is(member.id).first
      assert_equal "subject", message.subject
      assert_match /body/, message.body
    end

    assert_response :redirect
    assert_redirected_to complete_after_create_message_community_member_message_path(:id => community.id)
  end

  # コミュニティメンバーへのメッセージ作成キャンセル
  def test_create_message_cancel
    member = User.make
    community = set_community_and_members(member)

    assert_no_difference("Message.count") do
      get :create_message, :id => community.id,
          :receiver_ids => [member.id.to_s],
          :message => {:subject => "subject", :body => "body"},
          :cancel => 'Cancel'
    end

    assert_response :success
    assert_template "community_member_messages/message_form"
  end

  # コミュニティメンバーへのメッセージ作成失敗
  def test_create_message_fail
    member = User.make
    community = set_community_and_members(member)

    assert_no_difference("Message.count") do
      get :create_message, :id => community.id,
          :receiver_ids => [member.id.to_s],
          :message => {:subject => "subject", :body => ""},
          :cancel => 'Cancel'
    end

    assert !assigns(:message).valid?

    assert_response :success
    assert_template "community_member_messages/message_form"
  end
end

# コミュニティのメンバーへのメッセージを作成を行う
class CommunityMemberMessagesController < ApplicationController
  include Mars::Messageable

  before_filter :load_community
  before_filter :load_event
  before_filter :set_model_class
  before_filter :load_members

  before_filter :check_message_senderable_filter

  private
  # メンバーへメールを送る際、フォームから入力した内容を加工する
  def decorate(message)
    @body = message.body
    unless params[:event_id].blank?
      @event = CommunityEvent.find(params[:event_id])
      @user = @event.author
      message.body = render_to_string(:partial => "/community_member_messages/mail/inform_event", :layout => false)
    else
      @user = current_user
      message.body = render_to_string(:partial => "/community_member_messages/mail/inform", :layout => false)
    end
  end

  # メンバーへメッセージを作成したときに、メールを送信する:
  def send_mail(message, receivers)
    receivers.each do |receiver|
      message.receiver = receiver
      MessageNotifier.deliver_notification_by_row_message(message)
    end
  end

  def load_community
    if params[:id] && Community.exists?(params[:id])
      @community = Community.find(params[:id])
    end
  end

  def load_event
    if params[:event_id] && CommunityEvent.exists?(params[:event_id])
       @event = CommunityEvent.find(params[:event_id])
    end
  end

  def set_model_class
    if @event
      @model_class = @event.class
    else
      @model_class = @community.class
    end
  end

  def load_members
    if @event
      @members = @event.participations.select{ |member| !@event.author?(member) }
    else
      @members = @community.members.select{ |member| member.id != current_user.id }
    end
  end

  private

  # メッセージを送れるかどうかをチェックする
  def check_message_senderable_filter
    case
    when !logged_in?
      raise Mars::AccessDenied
    when @event && !@event.message_senderable?(@current_user)
      raise Mars::AccessDenied
    when !@community.member_message_senderable?(@current_user)
      raise Mars::AccessDenied
    end
  end

  # メッセージフォームで入力した内容をクリアしたときのレスポンス
  def response_for_confirm_before_create_message_at_clear
    redirect_to :action => :new_message, :id => params[:id], :receiver_ids => params[:receiver_ids], :event_id => @event.try(:id)
  end

  # メッセージ作成後のレスポンス
  def response_for_create_message
    redirect_to :action => :complete_after_create_message, :event_id => @event.try(:id)
  end
end

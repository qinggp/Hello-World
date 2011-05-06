# トモダチの管理を行うコントローラ
class FriendsController < ApplicationController
  include Mars::Messageable

  access_control do
    allow logged_in
  end

  # トモダチ管理画面トップ
  def index
    @user = params[:user_id].blank? ? current_user : User.find(params[:user_id])
    @title = "#{@user.name}さんのトモダチ一覧"
    if params[:group_id]
      @group = Group.find(params[:group_id])
      @friends = @group.friends.paginate(paginate_options_for_friends)
    else
      @friends = @user.friends.paginate(paginate_options_for_friends)
    end
    @groups = @user.groups
  end

  # 招待したトモダチ一覧
  def index_for_invite
    @user = User.find(params[:user_id])
    @friends = @user.friends.
      invitation_id_is(@user.id).
        paginate(paginate_options_for_friends)
  end

  # トモダチ管理画面
  def maintenance
    default_per_pagge = request.mobile? ? 10 : 5
    @friends = current_user.friends.
      paginate(paginate_options(:per_page => default_per_pagge,
                                :order => Friendship.default_index_order))
  end

  # 紹介文一覧表示ページ
  def list_description
    @friendships = Friendship.
      friend_id_is(displayed_user.id).
        description_not_null.
          paginate(paginate_options(:per_page => 20,
                                    :order => Friendship.default_index_order))
    @title = "#{displayed_user.name}さんの紹介文"
  end

  # トモダチ依頼中一覧
  def list_request
    @user = current_user
    @friendships = Friendship.by_applied_for_user(current_user).
        paginate(paginate_options(:per_page => 20,
                                  :order => Friendship.default_index_order).
                   merge(:include => :friend))
  end

  # トモダチ関係破棄確認画面
  def confirm_before_break_off
    @friend = User.find(params[:id])
    render "confirm_before_break_off"
  end

  # トモダチ関係を破棄する
  def break_off
    friend = User.find(params[:id])
    if current_user.invitation?(friend) || current_user.hot_friend?(friend)
      return redirect_to maintenance_friends_path
    end
    current_user.break_off!(friend)
    redirect_to maintenance_friends_path
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    friends_path
  end

  private
  # 一覧表示オプション
  def paginate_options(default_options = {})
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :per_page => (per_page_for_all(User) ? per_page_for_all(User) : default_options[:per_page]),
      :order => (params[:order] ? construct_sort_order : default_options[:order]),
    }
  end

  # トモダチ一覧表示オプション
  def paginate_options_for_friends
    return paginate_options(:per_page => 30, :order => User.default_index_order)
  end

  # トモダチ紹介メッセージ装飾
  def decorate(message)
    @body = message.body
    message.body = render_to_string(:partial => "/friends/mail/introduce_friend", :layout => false)
  end

  # トモダチ紹介メッセージを複数人に送信
  def send_mail(message, receivers)
    receivers.each do |receiver|
      message.receiver = receiver
      MessageNotifier.deliver_notification_by_row_message(message)
    end
  end
end

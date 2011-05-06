require File.dirname(__FILE__) + '/../../test_helper'

require 'date'
class Admin::StatisticsControllerTest < ActionController::TestCase
  # Replace this with your real tests.

  def setup
    @current_user ||= User.make(:admin => true)
    login_as(@current_user)

    # 日付の設定
    today = Date.today
    one_week_ago = Date.today - 7
    @aggregate_period_query = "created_at >= ? and created_at <= ?"
    @start_at = Time.local(one_week_ago.year, one_week_ago.month, one_week_ago.day, 0, 0, 0)
    @end_at = Time.local(today.year, today.month, today.day , 23, 59, 59)

    # 集計期間のパラメータの設定
        @set_date_params = {
    "start_at(1i)" => @start_at.year,
    "start_at(2i)" => @start_at.month,
    "start_at(3i)" => @start_at.day,
    "end_at(1i)" => @end_at.year,
    "end_at(2i)" => @end_at.month,
    "end_at(3i)" => @end_at.day
    }
  end

  # ユーザの総数を取得するテスト
  def test_users
    # 日付未選択
    get :index
    users = User.count

    assert_equal users, assigns(:users)

    # 日付選択
    get :index, :statistics => @set_data_params
    users = User.count(:conditions => ["#{@aggregate_period_query}", @start_at, @end_at])

    assert_equal users, assigns(:users)
  end

  # 承認待ちユーザ総数を取得するテスト
  def test_approval_waiting_user
    #日付未選択
    get :index
    approval_waiting_user = User.count(:conditions => ["approval_state = 'pending'"])

    assert_equal approval_waiting_user, assigns(:approval_waiting_users)

    # 日付選択
    get :index, :statistics => @set_data_params
    approval_waiting_user = User.count(:conditions => [@aggregate_period_query + " and approval_state = 'pending'", @start_at, @end_at])

    assert_equal approval_waiting_user, assigns(:approval_waiting_users)
  end

  # 一時停止中ユーザ総数
  def test_paused_user
    #日付未選択
    get :index
    paused_user = User.count(:conditions => ["approval_state = 'pause'"])

    assert_equal paused_user, assigns(:paused_users)

    # 日付選択
    get :index, :statistics => @set_data_params
    paused_user = User.count(:conditions => [@aggregate_period_query + " and approval_state = 'pause'", @start_at, @end_at])

    assert_equal paused_user, assigns(:paused_users)
  end

  # ログイン数を取得するテスト
  def test_today_logins
    get :index
    today = Date.today
    end_time = "#{today} 23:59:59"

    today_logins = User.count(:conditions => ['logged_in_at >= ? and logged_in_at <= ?', today, end_time])
    logins_within_one_week = User.count(:conditions => ['logged_in_at >= ? and logged_in_at <= ?', today - 7, end_time])
    logins_within_one_month = User.count(:conditions => ['logged_in_at >= ? and logged_in_at <= ?', today << 1, end_time])

    assert_equal today_logins, assigns(:today_logins)
    assert_equal logins_within_one_week, assigns(:logins_within_one_week)
    assert_equal logins_within_one_month, assigns(:logins_within_one_month)
  end

  # 招待中のユーザ数
  def test_invited_user
    invited_user = Invite.count
    get :index

    assert_equal invited_user, assigns(:invited_user)
  end

  # 招待しているユーザ数を取得するテスト
  def test_users_invited_users
    users_invited_users = Invite.count(:distinct => true, :select => 'user_id')
    get :index

    assert_equal users_invited_users, assigns(:users_invited_users)
  end

  # 友達リンク有効数を取得するテスト
  def test_friends
    friends = Friendship.count(:conditions => ['approved = true']) / 2
    get :index

    assert_equal friends, assigns(:friends)
  end

  #  友達リンク依頼数を取得するテスト
  def test_friend_request
    friend_request = Friendship.count(:conditions => ['approved = false'])
    get :index

    assert_equal friend_request, assigns(:friends_request)
  end

  # 紹介文の書き込み数を取得するテスト
  def test_friend_description
    # 集計期間未選択
    friend_description = Friendship.count(:conditions => ["approved = true and description is not null"])
    get :index

    assert_equal friend_description, assigns(:friend_description)

    # 集計期間選択
    friend_description = Friendship.count(
      :conditions => ["approved = true and description is not null and #{@aggregate_period_query}",
                                                     @start_at, @end_at])
    get :index, :statistics => @set_date_params
    assert_equal friend_description, assigns(:friend_description)
  end

  # コミュニティ数を取得するテスト
  def test_communities
    # 集計期間未選択
    communities = Community.count()
    get :index

    assert_equal communities, assigns(:communities)

    # 集計期間選択
    communities = Community.count(:conditions => [@aggregate_period_query, @start_at, @end_at])
    get :index, :statistics => @set_date_params

    assert_equal communities, assigns(:communities)
  end

  # コミュニティ管理者数を取得するテスト
  def test_community_admins
    # 集計期間未選択
    community_admins = Role.count(:conditions => ["name = ?", "community_admin"])
    get :index

    assert_equal community_admins, assigns(:community_admins)

    # 集計期間選択
    community_admins = Role.count(:conditions => ["name = ? and #{@aggregate_period_query}", "community_admin", @start_at, @end_at])
    get :index, :statistics => @set_date_params

    assert_equal community_admins, assigns(:community_admins)
  end

  # コミュニティトピック書き込み件数を取得するテスト
  def test_community_topics
    # 集計期間未選択
    community_topics = CommunityTopic.count
    get :index

    assert_equal community_topics, assigns(:community_topics)

    # 集計期間選択
    community_topics = CommunityTopic.count(:conditions => [@aggregate_period_query, @start_at, @end_at])
    get :index, :statistics => @set_date_params

    assert_equal community_topics, assigns(:community_topics)
  end

  # コミュニティ返信数を取得するテスト
  def test_community_replies
    # 集計期間未選択
    community_replies = CommunityReply.count(:conditions => ["deleted = ?", false])
    get :index

    assert_equal community_replies, assigns(:community_replies)

    # 集計期間選択
    community_replies = CommunityReply.count(:conditions => ["deleted = ? and " + @aggregate_period_query, false, @start_at, @end_at])
    get :index, :statistics => @set_date_params

    assert_equal community_replies, assigns(:community_replies)
  end

  # コミュニティ返信をした人数を取得するテスト
  def test_community_relies_user
    # 集計期間未選択
    community_replies_user = CommunityReply.count(:distinct => true, :select => 'user_id')
    get :index

    assert_equal community_replies_user, assigns(:community_replies_user)

    # 集計期間選択
    community_replies_user = CommunityReply.count(:conditions => [@aggregate_period_query, @start_at, @end_at],
                                                  :distinct => true, :select => 'user_id')
    get :index, :statistics => @set_date_params

    assert_equal community_replies_user, assigns(:community_replies_user)
  end

   # コミュニティイベント数を取得するテスト
  def test_community_events
    # 集計期間未選択
    community_events = CommunityEvent.count()
    get :index

    assert_equal community_events, assigns(:community_events)

    # 集計期間選択
    community_events = CommunityEvent.count(:conditions => [@aggregate_period_query, @start_at, @end_at])
    get :index, :statistics => @set_date_params

    assert_equal community_events, assigns(:community_events)
  end

  # コミュニティイベントを作成した人数を取得するテスト
  def test_community_events_user
    # 集計期間未選択
    community_events_user = CommunityEvent.count(:distinct => true, :select => 'user_id')
    get :index

    assert_equal community_events_user, assigns(:community_events_user)

    # 集計期間選択
    community_events_user = CommunityEvent.count(:conditions => [@aggregate_period_query, @start_at, @end_at],
                                                 :distinct => true, :select => 'user_id')
    get :index, :statistics => @set_date_params

    assert_equal community_events_user, assigns(:community_events_user)
  end

  # ブログの登録件数を取得するテスト
  def test_blog_entries
    # 集計期間未選択
    blog_entries = BlogEntry.count()
    get :index

    assert_equal blog_entries, assigns(:blog_entries)

    # 集計期間選択
    blog_entries = BlogEntry.count(:conditions => [@aggregate_period_query, @start_at, @end_at])
    get :index, :statistics => @set_date_params

    assert_equal blog_entries, assigns(:blog_entries)
  end

  # ブログの投稿人数を取得するテスト
  def test_blog_entries_user
    # 集計期間未選択
    blog_entries_user = BlogEntry.count(:distinct => true, :select => 'user_id')
    get :index

    assert_equal blog_entries_user, assigns(:blog_entries_user)

    # 集計期間選択
    blog_entries_user = BlogEntry.count(:conditions => [@aggregate_period_query, @start_at, @end_at],
                                        :distinct => true, :select => 'user_id')
    get :index, :statistics => @set_date_params

    assert_equal blog_entries_user, assigns(:blog_entries_user)
  end

   # ブログに対するコメントの登録件数を取得するテスト
  def test_blog_comments
    # 集計期間未選択
    blog_comments = BlogComment.count()
    get :index

    assert_equal blog_comments, assigns(:blog_comments)

    # 集計期間選択
    blog_comments = BlogComment.count(:conditions => [@aggregate_period_query, @start_at, @end_at])
    get :index, :statistics => @set_date_params

    assert_equal blog_comments, assigns(:blog_comments)
  end

  # ブログに対するコメントの投稿人数を取得するテスト
  def test_blog_comments_user
    # 集計期間未選択
    blog_comments_user = BlogComment.count(:distinct => true, :select => 'user_id')
    get :index

    assert_equal blog_comments_user, assigns(:blog_comments_user)

    # 集計期間選択
    blog_comments_user = BlogComment.count(:conditions => [@aggregate_period_query, @start_at, @end_at],
                                        :distinct => true, :select => 'user_id')
    get :index, :statistics => @set_date_params

    assert_equal blog_comments_user, assigns(:blog_comments_user)
  end

  # メッセージ数を取得するテスト
  def test_messages
    # 日付未選択
    messages = Message.count()
    get :index

    assert_equal messages, assigns(:messages)

    messages = Message.count(:conditions => [@aggregate_period_query, @start_at, @end_at])
    get :index, :statistics => @set_date_params

    assert_equal messages, assigns(:messages)
  end

  # メッセージ送信者数を取得するテスト
  def test_messages_sender_users
    # 日付未選択
    message_sender_users = Message.count(:distinct => true, :select => 'sender_id')
    get :index

    assert_equal message_sender_users, assigns(:message_sender_users)

    message_sender_users = Message.count(:conditions => [@aggregate_period_query, @start_at, @end_at],
                                       :distinct => true, :select => 'sender_id')
    get :index, :statistics => @set_date_params

    assert_equal message_sender_users, assigns(:message_sender_users)
  end

  # 男女比を取得するテスト
  def test_man_user_and_woman_user
    # 男性の人数
    man_user = User.count(:conditions => 'gender = 1')
    # 女性の人数
    woman_user = User.count(:conditions => 'gender = 2')

    get :index

    assert_equal man_user, assigns(:man_user)
    assert_equal woman_user, assigns(:woman_user)
  end

  # ユーザの年齢平均を取得するテスト
  def test_user_age_average

    get :index

    age_average = User.by_activate.all.map(&:age).inject(0) {
      |item, result| result += item} / User.by_activate.size.to_f
    assert_equal sprintf('%10.4f',age_average), assigns(:user_age_average)
  end
end

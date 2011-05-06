# 統計ページ管理
class Admin::StatisticsController < Admin::ApplicationController

  require "date"

  # 一覧の表示と並び替え，レコードの検索．
  def index
    if params[:statistics]
      start_at, end_at = aggregate_period(params[:statistics])
      aggregate_period_query = "created_at between ? and ?"
      @start_at = Time.local(*start_at)
      @end_at = Time.local(*end_at)
    end
    today = Date.today
    end_time = "#{today} 23:59:59"

    # ユーザ総数
    @users = User.count(:conditions => (aggregate_period_query ? [aggregate_period_query, @start_at, @end_at] : []))
    # 承認待ち総数
    @approval_waiting_users = User.count(:conditions => (aggregate_period_query ?
                                                         ["approval_state = ? and "  + aggregate_period_query, 'pending', @start_at, @end_at]:
                                                         ["approval_state = ?", 'pending']))

    # 一時停止中ユーザ
    @paused_users = User.count(:conditions => (aggregate_period_query ?
                                                ["approval_state = ? and "  + aggregate_period_query, 'pause', @start_at, @end_at] :
                                                ["approval_state = ?", 'pause']))

    # 本日ログイン数
    @today_logins = User.count(:conditions => ['logged_in_at >= ? and logged_in_at <= ?', today, end_time])
    # 最終ログイン１週間以内
    @logins_within_one_week = User.count(:conditions => ['logged_in_at >= ? and logged_in_at <= ?', today - 7, end_time])
    # 最終ログイン１ヶ月以内
    @logins_within_one_month = User.count(:conditions => ['logged_in_at >= ? and logged_in_at <= ?', today << 1, end_time])

    #　招待中のユーザ数
    @invited_user = Invite.count
    # 招待しているユーザ数
    @users_invited_users = Invite.count(:distinct => true, :select => 'user_id')

    # 友達リンク有効数
    @friends = Friendship.count(:conditions => ['approved = true']) / 2
    # 友達リンク依頼数
    @friends_request = Friendship.count(:conditions => ['approved = false'])

    # 紹介文書き込み数
    friend_description_query = 'approved = true and description is not null'
    @friend_description = Friendship.count(:conditions => (aggregate_period_query ?
                                                    ["#{friend_description_query} and " + aggregate_period_query, @start_at, @end_at] :
                                                    [friend_description_query]))

    # コミュニティ数
    @communities = Community.count(:conditions => (aggregate_period_query ? [aggregate_period_query, @start_at , @end_at] : []))
    # コミュニティ管理者数
    communit_admin_ids =
      Role.find(:all,
              :select => :id,
              :conditions => (aggregate_period_query ?
                              ["name = ? and " +  aggregate_period_query, "community_admin",@start_at, @end_at] :
                              ["name = ?", "community_admin"])).map(&:id)
    @community_admins =  RolesUser.count(:conditions => ["role_id IN (?)", communit_admin_ids],
                                         :distinct => true, :select => 'user_id')

    # コミュニティトピック書き込み件数
    @community_topics = CommunityTopic.count(:conditions => (aggregate_period_query ?
                                                              [aggregate_period_query, @start_at, @end_at] :
                                                              []))
    # コミュニティトピック書き込み人数
    @community_topics_user = CommunityThread.count(:conditions => (aggregate_period_query ?
                                                                   [aggregate_period_query, @start_at, @end_at] :
                                                                   []),
                                                   :distinct => true, :select => 'user_id')

    # コミュニティ返信数
    @community_replies = CommunityReply.count(:conditions => (aggregate_period_query ?
                                                             ["deleted = ? and " + aggregate_period_query, false, @start_at, @end_at] :
                                                             ["deleted = ?", false]))

    # コミュニティ返信人数
    @community_replies_user = CommunityReply.count(:conditions => (aggregate_period_query ?
                                                                  ["deleted = ? and " + aggregate_period_query, false, @start_at, @end_at] :
                                                                  ["deleted = ?", false]),
                                                  :distinct => true, :select => 'user_id')

    # コミュニティイベント数
    @community_events = CommunityEvent.count(:conditions => (aggregate_period_query ?
                                                            [aggregate_period_query, @start_at, @end_at] :
                                                            []))

    # コミュニティイベント人数
    @community_events_user = CommunityEvent.count(:conditions => (aggregate_period_query ?
                                                                  [aggregate_period_query, @start_at, @end_at] :
                                                                  []),
                                                  :distinct => true, :select => 'user_id')

    # ブログ数
    @blog_entries = BlogEntry.count(:conditions => (aggregate_period_query ?
                                                   [aggregate_period_query, @start_at, @end_at] :
                                                   []))

    # ブログ投稿人数
    @blog_entries_user = BlogEntry.count(:conditions => (aggregate_period_query ?
                                                        [aggregate_period_query, @start_at, @end_at] :
                                                        []),
                                         :distinct => true, :select => 'user_id')

    # ブログコメント数
    @blog_comments = BlogComment.count(:conditions => (aggregate_period_query ?
                                                      [aggregate_period_query, @start_at, @end_at] :
                                                      []))

    # ブログコメント投稿人数
    @blog_comments_user = BlogComment.count(:conditions => (aggregate_period_query ?
                                                            [aggregate_period_query, @start_at, @end_at] :
                                                            []),
                                             :distinct => true, :select => 'user_id')

    # メッセージ数(実装完了)
    @messages = Message.count(:conditions => (aggregate_period_query ?
                                             [aggregate_period_query, @start_at, @end_at] :
                                             []))

    # メッセージ送信者数(実装完了)
    @message_sender_users = Message.count(:conditions => (aggregate_period_query ?
                                                       [aggregate_period_query, @start_at, @end_at] :
                                                       []),
                                        :distinct => true, :select => 'sender_id')

    # 男性の人数
    @man_user = User.count(:conditions => 'gender = 1')
    # 女性の人数
    @woman_user = User.count(:conditions => 'gender = 2')

    @user_age_average = sprintf('%10.4f',
                                User.by_activate.all.map(&:age).inject(0) {|item, result| result += item} / User.by_activate.size.to_f)


  end


private

  # 集計期間を返す
  def aggregate_period(period)
    start_at = [period["start_at(1i)"], period["start_at(2i)"], period["start_at(3i)"], 0, 0, 0]
    end_at = [period["end_at(1i)"], period["end_at(2i)"], period["end_at(3i)"], 23, 59, 59]
    return start_at, end_at
  end

end

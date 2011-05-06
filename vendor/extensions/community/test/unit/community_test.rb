require File.dirname(__FILE__) + '/../test_helper'

class CommunityTest < ActiveSupport::TestCase

  # コミュニティの管理人を取得するメソッドのテスト
  def test_admin
    @current_user = User.make
    community = set_community_and_has_role

    assert_equal @current_user.id, community.admin.id

    # 他のコミュニティの管理人にもなる
    other_community = set_community_and_has_role

    assert_equal @current_user.id, community.admin.id
    assert_equal @current_user.id, other_community.admin.id

    # 最初のコミュニティの管理人をやめる
    community.accepts_no_role!("community_admin", @current_user)

    assert_nil community.admin
    assert_equal @current_user.id, other_community.admin.id
  end

  # コミュニティが開設されてからの経過日数を返すメソッドをテスト
  def test_elapsed_days
    community = Community.make
    assert_equal 1, community.elapsed_days

    community.update_attributes(:created_at => Time.now.yesterday)
    assert_equal 2, community.elapsed_days
  end

  # 管理人であるかどうか、または副管理人であるかどうかを返すメソッドをテスト
  def test_check_authority
    @current_user = User.make
    community = set_community_and_has_role
    assert community.admin?(@current_user)

    community.accepts_no_role!("community_admin", @current_user)
    assert !community.admin?(@current_user)

    community = set_community_and_has_role("community_sub_admin")
    assert community.sub_admin?(@current_user)

    community.accepts_no_role!("community_sub_admin", @current_user)
    assert !community.sub_admin?(@current_user)
  end

  # トピック、またはマーカーが管理者のみ作成可能かどうか返すメソッドをテスト
  def test_topic_and_marker_createable_admin_only
    community = Community.make(:topic_createable_admin_only => true)
    assert_equal true, community.topic_and_marker_createable_admin_only?

    community = Community.make(:topic_createable_admin_only => false)
    assert_equal false, community.topic_and_marker_createable_admin_only?
  end

  # イベントが管理者のみ作成可能かどうか返すメソッドをテスト
  def test_event_createable_admin_only
    community = Community.make(:event_createable_admin_only => true)
    assert_equal true, community.event_createable_admin_only?

    community = Community.make(:event_createable_admin_only => false)
    assert_equal false, community.event_createable_admin_only?
  end

  # ログインユーザがトピック、またはマーカーを作成可能かどうかを返すメソッドをテスト
  def test_topic_and_marker_createable
    community = Community.make(:topic_createable_admin_only => false)
    user = User.make
    assert !community.topic_and_marker_createable?(user)

    member = User.make
    community.members << member
    community.accepts_role!(:community_general, member)
    assert community.topic_and_marker_createable?(member)

    sub_admin = User.make
    community.members << sub_admin
    community.accepts_role!(:community_sub_admin, sub_admin)
    assert community.topic_and_marker_createable?(sub_admin)

    admin = User.make
    community.members << admin
    community.accepts_role!(:community_admin, admin)
    assert community.topic_and_marker_createable?(admin)

    community = Community.make(:topic_createable_admin_only => true)
    user = User.make
    assert !community.topic_and_marker_createable?(user)

    member = User.make
    community.members << member
    community.accepts_role!(:community_general, member)
    assert !community.topic_and_marker_createable?(member)

    sub_admin = User.make
    community.members << sub_admin
    community.accepts_role!(:community_sub_admin, sub_admin)
    assert community.topic_and_marker_createable?(sub_admin)

    admin = User.make
    community.members << admin
    community.accepts_role!(:community_admin, admin)
    assert community.topic_and_marker_createable?(admin)
  end

  # ログインユーザがイベントを作成可能かどうかを返すメソッドをテスト
  def test_event_createable
    community = Community.make(:event_createable_admin_only => false)
    user = User.make
    assert !community.event_createable?(user)

    member = User.make
    community.members << member
    community.accepts_role!(:community_general, member)
    assert community.event_createable?(member)

    sub_admin = User.make
    community.members << sub_admin
    community.accepts_role!(:community_sub_admin, sub_admin)
    assert community.event_createable?(sub_admin)

    admin = User.make
    community.members << admin
    community.accepts_role!(:community_admin, admin)
    assert community.event_createable?(admin)

    community = Community.make(:event_createable_admin_only => true)
    user = User.make
    assert !community.event_createable?(user)

    member = User.make
    community.members << member
    community.accepts_role!(:community_general, member)
    assert !community.event_createable?(member)

    sub_admin = User.make
    community.members << sub_admin
    community.accepts_role!(:community_sub_admin, sub_admin)
    assert community.event_createable?(sub_admin)

    admin = User.make
    community.members << admin
    community.accepts_role!(:community_admin, admin)
    assert community.event_createable?(admin)
  end

  # トピック、マーカー、イベントのどれかが作成可能かどうかを返すメソッドのテスト
  def test_some_thread_createable
    community = Community.make(:event_createable_admin_only => false,
                               :topic_createable_admin_only => false)

    user = User.make
    member = User.make
    sub_admin = User.make
    admin = User.make

    community.members << [member, sub_admin, admin]
    community.accepts_role!("community_general", member)
    community.accepts_role!("community_sub_admin", sub_admin)
    community.accepts_role!("community_admin", admin)

    assert !community.some_thread_createable?(user)
    assert community.some_thread_createable?(member)
    assert community.some_thread_createable?(sub_admin)
    assert community.some_thread_createable?(admin)

    community.update_attributes!(:event_createable_admin_only => true,
                                 :topic_createable_admin_only => false)
    assert !community.some_thread_createable?(user)
    assert community.some_thread_createable?(member)
    assert community.some_thread_createable?(sub_admin)
    assert community.some_thread_createable?(admin)

    community.update_attributes!(:event_createable_admin_only => false,
                                 :topic_createable_admin_only => true)
    assert !community.some_thread_createable?(user)
    assert community.some_thread_createable?(member)
    assert community.some_thread_createable?(sub_admin)
    assert community.some_thread_createable?(admin)

    community.update_attributes!(:event_createable_admin_only => true,
                                 :topic_createable_admin_only => true)
    assert !community.some_thread_createable?(user)
    assert !community.some_thread_createable?(member)
    assert community.some_thread_createable?(sub_admin)
    assert community.some_thread_createable?(admin)
  end

  # あるユーザが所属するコミュニティのトピック、イベント、マーカに対して、最終投稿順でソートして返すメソッドのテスト
  def test_threads_order_by_post
    # NOTE: fixturesに、公認（管理人）が存在するので、current_userは作成された時点でそこに所属してしまうので、ここで削除する
    Community.destroy_all

    @current_user = User.make
    community = set_community_and_has_role

    # 最初と最後になるであろうスレッドを作成
    first_thread = community.topics.make(:lastposted_at => Time.now.tomorrow)
    last_thread = community.topics.make(:lastposted_at => Time.now.years_ago(1))

    # その他30スレッドを作成
    other_topic_numbers = 10
    other_event_numbers = 10
    other_marker_numbers = 10
    total_numbers =
      2 + other_topic_numbers + other_event_numbers + other_marker_numbers
    other_topic_numbers.times { community.topics.make }
    other_event_numbers.times { community.events.make}
    other_marker_numbers.times { community.markers.make}

    # 最新スレッドを全件取得
    threads = Community.threads_order_by_post(@current_user)
    assert_equal total_numbers, threads.size
    assert_equal first_thread.id, threads.first.id
    assert_equal last_thread.id, threads.last.id

    # 上位10件を取得
    limit = 10
    threads = Community.threads_order_by_post(@current_user, :limit => limit)
    assert_equal limit, threads.size
    assert_equal first_thread.id, threads.first.id
    assert !threads.map(&:id).include?(last_thread.id)

    # 3日前以降に更新があったスレッドを取得
    days_ago = 3
    threads = Community.threads_order_by_post(@current_user, :days_ago => days_ago)
    assert_equal total_numbers - 1, threads.size
    assert_equal first_thread.id, threads.first.id
    assert !threads.map(&:id).include?(last_thread.id)

    # 非表示設定とすると、取得できない
    community.change_new_comment_displayed(@current_user)
    @current_user.reload
    threads = Community.threads_order_by_post(@current_user)
    assert_equal 0, threads.size
  end

  # あるユーザが所属していて、かつ投稿したコメントを取得するメソッドのテスト
  def test_comments_post
    @current_user = User.make
    community = set_community_and_has_role

    # トピック、マーカー、イベントをそれぞれ1つずつ作成し、コメントも一件ずつ作成する
    topic = community.topics.make(:author => @current_user)
    topic.replies.make(:author => @current_user, :community => community)

    event = community.events.make(:author => @current_user)
    event.replies.make(:author => @current_user, :community => community)

    marker = community.markers.make(:author => @current_user)
    marker.replies.make(:author => @current_user, :community => community)

    # 最新のものとして、一件追加
    latest_topic = community.topics.make(:author => @current_user, :created_at => Time.now.tomorrow)

    # 10日前を追加
    old_topic = community.topics.make(:author => @current_user, :created_at => Time.now.advance(:days => -10))

    # 古すぎて表示されないものを一件追加
    oldest_topic = community.topics.make(:author => @current_user, :created_at => Time.now.years_ago(1))

    # デフォルトの30日前までに投稿されたコメントを取得する
    comments = Community.comments_post(@current_user, :vpublic_or_member_visibility => true)
    assert_equal 8, comments.size
    assert_equal latest_topic.id, comments.first.id
    assert !comments.map(&:id).include?(oldest_topic.id)

    # 3日前までに投稿されたコメントを取得する
    comments = Community.comments_post(@current_user, :days_ago => 3)
    assert_equal 7, comments.size
    assert_equal latest_topic.id, comments.first.id
    assert !comments.map(&:id).include?(oldest_topic.id)
    assert !comments.map(&:id).include?(old_topic.id)

    # 最新5件までを取得する
    comments = Community.comments_post(@current_user, :limit => 5)
    assert_equal 5, comments.size
    assert_equal latest_topic.id, comments.first.id
    assert !comments.map(&:id).include?(oldest_topic.id)

    # 非公開のコミュニティを追加し、トピックを一件追加
    member_community = set_community_and_has_role(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_private])
    topic = member_community.topics.make(:author => @current_user)

    # コミュニティの公開範囲を絞らない場合
    comments = Community.comments_post(@current_user, :vpublic_or_member_visibility => false)
    assert_equal 9, comments.size

    # 外部公開、または全体公開のコミュニティみの場合
    comments = Community.comments_post(@current_user, :vpublic_or_member_visibility => true)
    assert_equal 8, comments.size
  end

  # 新着のトピック、イベント、マーカの取得
  def test_publiced_threads_order_by_post
    community = Community.make
    topic = community.topics.make
    marker = community.markers.make
    event = community.events.make

    community = Community.make(:visibility => Community::VISIBILITIES[:private])
    not_hit_topic = community.topics.make

    res = Community.publiced_threads_order_by_post(:limit => 20)

    assert_equal true, res.any?{|r| r.id == topic.id }
    assert_equal true, res.any?{|r| r.id == marker.id }
    assert_equal true, res.any?{|r| r.id == event.id }
    assert_equal false, res.any?{|r| r.id == not_hit_topic.id }
  end

  # コミュニティに紐付く、新着のトピック、イベント、マーカ、それに対す
  # るコメント取得
  def test_publiced_threads_order_by_post
    community = Community.make
    topic = community.topics.make
    marker = community.markers.make
    event = community.events.make
    comment = event.replies.make(:community => community)
    deleted_comment = event.replies.make(:community => community, :deleted => true)

    res = community.threads_and_comments_order_by_post(20)

    assert_equal true, res.any?{|r| r.id == topic.id }
    assert_equal true, res.any?{|r| r.id == marker.id }
    assert_equal true, res.any?{|r| r.id == event.id }
    assert_equal true, res.any?{|r| r.id == comment.id }
    assert_equal false, res.any?{|r| r.id == deleted_comment.id }

    res = community.threads_and_comments_order_by_post(1)

    assert_equal 1, res.size
    assert_equal comment, res.first
  end

  # コミュニティへの書き込み通知設定変更するメソッドのテスト
  def test_update_comment_notice_acceptable
    @current_user = User.make
    community = set_community_and_has_role

    attr = {
      :comment_notice_acceptable => true,
      :comment_notice_acceptable_for_mobile => true
    }

    community.update_comment_notice_acceptable(@current_user, attr)
    assert community.comment_notice_acceptable?(@current_user)
    assert community.comment_notice_acceptable_for_mobile?(@current_user)

    attr = { :comment_notice_acceptable => false }
    community.update_comment_notice_acceptable(@current_user, attr)
    assert !community.comment_notice_acceptable?(@current_user)
    assert community.comment_notice_acceptable_for_mobile?(@current_user)
  end

  # 公認コミュニティかどうかを返すメソッドのテスト
  def test_official
    Community::OFFICIALS.each do |key, value|
      community = Community.make(:official => value)

      case key
      when :none
        assert !community.official?
      else
        assert community.official?
      end
    end
  end

  # コミュニティ削除
  def test_community_destroy
    user = User.make
    community = set_community_and_has_role(user)
    PendingCommunityUser.make(:community => community, :user => User.make)
    CommunityInnerLinkage.make(:owner => community, :inner_link => Community.make)
    CommunityInnerLinkage.make(:owner => Community.make, :inner_link => community)
    community.members << User.make
    CommunityMapCategory.make(:community => community)
    community.groups << CommunityGroup.make(:user => user)

    [CommunityTopic, CommunityMarker, CommunityEvent].each do |klass|
      thread = klass.make(:community => community)
      reply = CommunityReply.make(:community => community, :thread => thread)
    end
    community.save!

    assert_not_nil PendingCommunityUser.find_by_community_id(community.id)
    assert_not_nil CommunityInnerLinkage.find_by_community_id(community.id)
    assert_not_nil CommunityInnerLinkage.find_by_link_id(community.id)
    assert_not_nil CommunityMembership.find_by_community_id(community.id)
    assert_not_nil CommunityMapCategory.find_by_community_id(community.id)
    assert_not_nil CommunityGroupMembership.find_by_community_id(community.id)
    assert_not_nil CommunityGroup.find_by_user_id(user.id)
    [CommunityTopic, CommunityMarker, CommunityEvent].each do |klass|
      assert_not_nil klass.find_by_community_id(community.id)
      assert_not_nil CommunityReply.find_by_community_id(community.id)
    end

    community.destroy

    assert_nil PendingCommunityUser.find_by_community_id(community.id)
    assert_nil CommunityInnerLinkage.find_by_community_id(community.id)
    assert_nil CommunityInnerLinkage.find_by_link_id(community.id)
    assert_nil CommunityMembership.find_by_community_id(community.id)
    assert_nil CommunityMapCategory.find_by_community_id(community.id)
    assert_nil CommunityGroupMembership.find_by_community_id(community.id)
    assert_not_nil CommunityGroup.find_by_user_id(user.id)  # これは消えない
    [CommunityTopic, CommunityMarker, CommunityEvent].each do |klass|
      assert_nil klass.find_by_community_id(community.id)
      assert_nil  CommunityReply.find_by_community_id(community.id)
    end
  end

  # ユーザ削除
  # ユーザは自分が管理人だが、他にだれもいないコミュニティのメンバー
  def test_user_destroy_when_only_member
    user = User.make
    community = set_related_community_data_for_destroy(user, "community_admin")
    assert community.admin?(user)
    admin_communities = CommunityMembership.admin_communities(user)
    assert_equal community.id, admin_communities.first.id

    user.destroy

    # コミュニティ自体削除される
    assert_nil Community.find_by_id(community.id)
  end

  # ユーザ削除
  # 自分が管理人で、他に誰かいるとき
  def test_user_destroy_when_community_admin
    user = User.make
    other_member = User.make
    community = set_related_community_data_for_destroy(user, "community_admin",
                                                      :other_member => other_member)
    user.destroy

    other_member.reload
    # 管理権限の委譲
    assert !community.admin?(user)
    assert community.admin?(other_member)

    # マップカテゴリの作成者を委譲
    assert !CommunityMapCategory.community_id_is(community.id).user_id_is(other_member.id).blank?

    # userが作成したスレッドが削除されている
    assert_nil CommunityThread.find_by_user_id(user.id)

    # userが返信したデータはdeletedになっている
    assert_not_nil CommunityReply.user_id_is(user.id)
    CommunityReply.user_id_is(user.id).each do |r|
      assert r.deleted
    end

    # イベントへの参加情報が削除されている
    assert_nil CommunityEventMember.find_by_user_id(user.id)

    # コミュニティグループが削除されている
    assert_nil CommunityGroup.find_by_user_id(user.id)
  end

  # ユーザ削除
  # 自分が管理人ではないコミュニティ
  def test_user_destroy_when_not_community_admin
    user = User.make
    other_member = User.make
    community = set_related_community_data_for_destroy(user, "community_general")

    user.destroy

    # userが作成したスレッドが削除されている
    assert_nil CommunityThread.find_by_user_id(user.id)

    # userが返信したデータはdeletedになっている
    assert_not_nil CommunityReply.user_id_is(user.id)
    CommunityReply.user_id_is(user.id).each do |r|
      assert r.deleted
    end

    # イベントへの参加情報が削除されている
    assert_nil CommunityEventMember.find_by_user_id(user.id)

    # コミュニティグループが削除されている
    assert_nil CommunityGroup.find_by_user_id(user.id)
  end

  # ユーザ退会処理
  # コミュニティ参加者をメンバーから外したときの処理をテスト
  def test_remove_member
    user = User.make
    community = set_related_community_data_for_destroy(User.make, "community_admin", :other_member => user)

    # コミュニティグループを作成し、そこにcommunityを追加する
    group = CommunityGroup.make(:user => user)
    group.add_community(community)

    assert group.has_community?(community)
    assert community.member?(user)

    group.reload
    community.reload

    community.remove_member!(user)
    assert !group.has_community?(community)
    assert !community.member?(user)
  end

  # 公認コミュニティ（全員）の初期化処理
  def test_add_members_to_official_type_all_membr
    User.destroy_all
    user = User.make
    active_user = User.make(:approval_state => "active")
    pending_user = User.make(:approval_state => "pending")
    pause_user = User.make(:approval_state => "pause")
    community = set_community_and_has_role(user, :official => Community::OFFICIALS[:all_member])

    assert_difference "CommunityMembership.count", 2 do
      community.add_members_to_official
    end

    community.reload
    assert community.member?(active_user)
    assert community.member?(pending_user)
    assert !community.member?(pause_user)
  end

  # 公認コミュニティ（管理人）の初期化処理
  def test_add_members_to_official_type_admin_only
    User.destroy_all
    user = User.make
    community = set_community_and_has_role(user, :official => Community::OFFICIALS[:admin_only])

    # NOTE: pendingの状態を作るため
    SnsConfig.master_record.update_attributes!(:approval_type => SnsConfig::APPROVAL_TYPES[:approved_by_administrator])

    active_user = User.make(:approval_state => "active")
    pending_user = User.make(:approval_state => "pending")
    pause_user = User.make(:approval_state => "pause")

    assert_no_difference "CommunityMembership.count" do
      community.add_members_to_official
    end

    [active_user, pending_user, pause_user].each do |u|
      set_community_and_has_role(u)
    end

    assert_difference "CommunityMembership.count" do
      community.add_members_to_official
    end

    community.reload
    assert community.member?(active_user)
    assert !community.member?(pending_user)
    assert !community.member?(pause_user)
  end

  # ユーザ作成時に、管理人（全員）コミュニティに参加させられることをテスト
  def test_add_member_to_official_all_member
    Community.destroy_all
    community = Community.make(:official => Community::OFFICIALS[:all_member])

    user = nil
    assert_difference "CommunityMembership.count" do
      user = User.make
    end

    community.reload
    community.member?(user)
  end

  # コミュニティ管理権限委譲メソッドのテスト
  def test_delegate_admin_to
    official_community_admin_only = Community.make(:official => Community::OFFICIALS[:admin_only])

    admin = User.make
    community = set_community_and_has_role(admin)

    next_admin = User.make
    community.members << next_admin
    next_admin.has_role!("community_general", community)

    community.delegate_admin_to(next_admin)

    assert community.admin?(next_admin)
    assert !community.admin?(admin)

    assert official_community_admin_only.member?(next_admin)
    assert !official_community_admin_only.member?(admin)
  end

  # 管理しているコミュニティの数
  def test_admin_communities_count
    user = User.make
    admin_community = set_community_and_has_role(user)
    sub_admin_community = set_community_and_has_role(user, "community_sub_admin")
    general_community = set_community_and_has_role(user, "community_general")

    assert_equal 1, Community.admin_communities_count(user)
  end

  private

  # 削除確認用に関連データの作成
  def set_related_community_data_for_destroy(user, role, options = {})
    community = Community.make

    # userをコミュニティに参加させる処理
    PendingCommunityUser.make(:user => user, :community => community)
    community.members << user
    user.has_role!(role, community)

    if options[:other_member]
      other_member = options.delete(:other_member)
      community.members << other_member
      other_member.has_role!("community_general", community)
    end

    # userがトピック、イベント、マーカーとそれへの返信を作成
    [CommunityTopic, CommunityEvent, CommunityMarker].each do |klass|
      thread = klass.make(:author => user, :community => community)
      reply = CommunityReply.make(:community => community, :thread => thread, :author => user)
    end

    # 他のユーザがトピック、イベント、マーカーを作成し、userが返信を作成
    [CommunityTopic, CommunityEvent, CommunityMarker].each do |klass|
      thread = klass.make(:author => User.make, :community => community)
      reply = CommunityReply.make(:community => community, :thread => thread, :author => user)
    end

    # イベントにuserを参加させる
    event = CommunityEvent.community_id_is(community.id).first
    event.participations << user

    # コミュニティグループを作成し、グループのコミュニティにcommunityを追加する
    group = CommunityGroup.make(:user => user)
    group.communities << community

    # コミュニティマップカテゴリを作成する
    CommunityMapCategory.make(:community => community, :author => user)

    community.save!
    community
  end
end

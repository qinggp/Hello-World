require File.dirname(__FILE__) + '/../test_helper'

class CommunityEventTest < ActiveSupport::TestCase

  # 現在開催中のイベント一覧を取得するメソッドのテスト
  def test_events_open
    community = Community.make

    assert_equal 0, community.events.open.count

    # イベントを追加するが、明日開催と昨日開催
    CommunityEvent.make(:community => community, :event_date => Time.now.tomorrow)
    CommunityEvent.make(:community => community, :event_date => Time.now.yesterday)

    assert_equal 0, community.events.open.count

    # 今日開催のイベントを追加
    CommunityEvent.make(:community => community, :event_date => Time.now)
    assert_equal 1, community.events.open.count
  end

  # 最新書込一覧を取得するメソッドのテスト
  def test_latest_events
    CommunityEvent.destroy_all

    community = Community.make
    total_event = 10

    total_event.times do |num|
      event = CommunityEvent.make(:title => num,
                                  :community => community)
      event.update_attributes(:created_at => Time.now + num)
    end

    latest_events = community.events.lastposts

    latest_events.each_with_index do |event, index|
      assert_equal total_event - (index + 1), event.title.to_i
    end
  end

  # ユーザがイベントに参加するメソッドのテスト
  def test_participate_in
    # コミュニティのメンバーで無ければ参加できない
    user = User.make
    event = create_event
    assert_no_difference "CommunityEventMember.count" do
      event.participate_in(user)
    end
    assert !event.participations?(user)

    # コミュニティのメンバーであれば参加できる
    user = User.make
    event = create_event(user)
    assert_difference "CommunityEventMember.count" do
      event.participate_in(user)
    end
    assert event.participations?(user)
  end

  # ユーザをイベントから外すメソッドのテスト
  def test_cancel_participation
    user = User.make
    event = create_event
    event.community.members << user
    user.has_role!("community_general", event.community)

    event.participate_in(user)

    event.cancel_participation(user)
    assert !event.participations?(user)

    # イベント作成者は外せない
    user = User.make
    event = create_event(user)

    event.cancel_participation(user)
    assert event.participations?(user)
  end

  # イベント作成時に、イベント参加者に作成者を追加されているかテスト
  def test_add_author_to_event_members
    author = User.make

    event = nil
    assert_difference "CommunityEventMember.count" do
      event = create_event(author)
    end

    assert event.participations?(author)
  end

  # ユーザがイベント参加者かどうかを返すメソッドのテスト
  def test_participations?
    user = User.make
    event = create_event
    event.community.members << user
    user.has_role!("community_general", event.community)

    assert !event.participations?(user)

    event.participate_in(user)
    assert event.participations?(user)
  end

  # イベント作成・削除時に対応するカラムの数が変動するか
  def test_events_count
    community = Community.make
    assert_equal 0, community.events_count

    event = CommunityEvent.make(:community_id => community.id)
    community.reload
    assert_equal 1, community.events_count

    event.destroy
    community.reload
    assert_equal 0, community.events_count
  end

  private

  # イベントを作成する
  # イベント作成者は、コミュニティに所属させる
  def create_event(author = User.make)
    community = set_community_and_has_role(User.make)

    community.members << author
    author.has_role!("community_general", community)
    event = CommunityEvent.make(:community => community, :author => author)
  end
end


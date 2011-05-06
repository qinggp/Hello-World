require File.dirname(__FILE__) + '/../test_helper'

class CommunityReplyTest < ActiveSupport::TestCase

  def setup
    @user = User.make
    @community = Community.make
    @thread = CommunityTopic.make(:community => @community)
    @reply =  CommunityReply.make(:community => @community,
                                  :thread => @thread)
  end

  # 返信作成者をイベントに参加させたり外すメソッドのテスト
  def test_create_or_delete_event_member
    user = User.make
    event = CommunityEvent.make
    reply = CommunityReply.make(:thread => event, :author => user)
    event.community.members << user
    user.has_role!("community_general", event.community)

    assert !event.participations?(user)
    reply.create_or_delete_event_member
    event.reload
    assert event.participations?(user)

    reply.create_or_delete_event_member
    event.reload
    assert !event.participations?(user)
  end

  # 編集できるかどうかを返すメソッドのテスト
  def test_editable
    # 全く関係無い場合
    assert !@reply.editable?(@user)

    # ただの参加者である場合
    @community.members << @user
    @user.has_role!("community_general", @community)
    assert !@reply.editable?(@user)


    # 副管理人である場合
    @user.has_no_roles_for!(@community)
    @user.has_role!("community_sub_admin", @community)
    assert @reply.editable?(@user)


    # 管理人である場合
    @user.has_no_roles_for!(@community)
    @user.has_role!("community_admin", @community)
    assert @reply.editable?(@user)

    # 自分が作成した場合
    @user.has_no_roles_for!(@community)
    @user.has_role!("community_general", @community)
    @reply = CommunityReply.make(:community => @community,
                                 :thread => @thread,
                                 :author => @user)
    assert @reply.editable?(@user)
  end

  # 新規作成時に正しくタイトルが設定されているか確認する
  def test_initiali_title
    # トピックへの直接の返信
    @thread.update_attributes!(:title => "title")
    assert_equal "Re: title", CommunityReply.new(:thread => @thread, :community => @community).default_subject

    # 返信の返信
    first_reply = CommunityReply.make(:thread => @thread, :community => @community, :title => "Re: title")
    assert_equal "Re[2]: title", CommunityReply.new(:thread => @thread, :community => @community, :parent => first_reply).default_subject
    reply_to_first_reply = CommunityReply.new(:thread => @thread, :community => @community, :parent => first_reply, :title => "Re[2]: title")
    assert_equal "Re[3]: title", CommunityReply.new(:thread => @thread, :community => @community, :parent => reply_to_first_reply).default_subject

    # トピックのタイトルとは無関係にタイトルを設定した返信と、さらにその返信
    second_reply = CommunityReply.make(:thread => @thread, :community => @community, :title => "reply")
    assert_equal "Re: reply", CommunityReply.new(:thread => @thread, :community => @community, :parent => second_reply).default_subject
  end

  # 返信元のcontentを引用文として現在のcontentに含める
  def test_quote_content
    # 返信元がスレッドで、作成しようとする返信文が空のとき
    author = User.make(:name => "author")
    thread = CommunityTopic.make(:content => "content\n\ncontent",
                                 :author => author)
    reply = CommunityReply.new(:thread => thread,
                               :content => "")
    expected_quote_content = "authorさんの発言\n> content\n> \n> content"
    assert_equal expected_quote_content, reply.quote_content

    # 返信元がトピックで、作成しようとする返信文が空のとき
    quoted_reply = CommunityReply.new(:content => "content\n\ncontent",
                                      :author => author)
    reply = CommunityReply.new(:parent => quoted_reply,
                               :content => "")
    assert_equal expected_quote_content, reply.quote_content

    # 返信元がスレッドで、作成しようとする返信文が既になにか入力されているとき
    reply = CommunityReply.new(:thread => thread,
                               :content => "hello.\nworld.")
    expected_quote_content = "hello.\nworld.\n\nauthorさんの発言\n> content\n> \n> content"
    assert_equal expected_quote_content, reply.quote_content

    # 返信元がトピックで、作成しようとする返信文が空のとき
    quoted_reply = CommunityReply.new(:content => "content\n\ncontent",
                                      :author => author)
    reply = CommunityReply.new(:parent => quoted_reply,
                               :content => "hello.\nworld.")
    assert_equal expected_quote_content, reply.quote_content
  end

  # 作成されたとき、自身のlastposted_atと参照先のコミュニティとスレッドののlastposted_atが更新されることを確認する
  def test_save_lastposted_at
    stub(Time).now{ Time.local(2020, 10, 10, 10, 10, 10) }

    assert_not_equal @community.reload.lastposted_at, Time.now
    assert_not_equal @thread.reload.lastposted_at, Time.now

    CommunityReply.make(:community => @community, :thread => @thread)
    assert_equal Time.now, @thread.reload.lastposted_at
    assert_equal Time.now, @community.reload.lastposted_at
  end

  # 論理削除するメソッドのテスト
  def test_set_deleted_flag
    assert !@reply.deleted
    @reply.set_deleted_flag
    @reply.reload
    assert @reply.deleted
  end
end

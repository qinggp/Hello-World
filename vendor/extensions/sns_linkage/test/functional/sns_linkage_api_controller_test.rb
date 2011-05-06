require File.dirname(__FILE__) + '/../test_helper'
require 'digest/sha1'
require 'rss/2.0'

class SnsLinkageApiControllerTest < ActionController::TestCase
  def setup
    user = User.make
    SnsLinkage.set_link_key!(user)
    user.save!
    @test_user = user
  end

  # お知らせ情報表示
  def test_info
    new_info = Information.make(:title => "new_info",
                                :display_type => Information::DISPLAY_TYPES[:new],
                                :display_link => Information::DISPLAY_LINKS[:no_link])
    important_info = Information.make(:title => "important_info",
                                      :display_type => Information::DISPLAY_TYPES[:important])
    fixed_info = Information.make(:title => "fixed_info",
                                  :display_type => Information::DISPLAY_TYPES[:fixed])

    @request.env['QUERY_STRING'] = @test_user.sns_link_key + ".info"
    get :show

    # puts @response.body
    res = RSS::Parser.parse(@response.body)

    item = res.channel.items.detect{|i| important_info.title == i.title}
    assert_equal important_info.title, item.title
    assert_equal information_url(important_info), item.link
    assert_equal "重要なお知らせ", item.category.content

    item = res.channel.items.detect{|i| new_info.title == i.title}
    assert_equal new_info.title, item.title
    assert_equal "", item.link
    assert_equal SnsConfig.title, item.author
    assert_equal "お知らせ", item.category.content

    assert_equal false, res.channel.items.any?{|i| fixed_info.title == i.title}
  end

  # 注目情報表示
  def test_notice
    friend = User.make
    Friendship.make(:user => friend, :friend => @test_user, :approved => false)

    Message.make(:receiver_id => @test_user.id, :unread => true)
    if SnsLinkageExtension.instance.extension_enabled?(:community)
      com =  Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_public])
      com.members << @test_user
      @test_user.has_role!("community_admin", com)
      PendingCommunityUser.make(:community => com, :user => @test_user)
    end

    @request.env['QUERY_STRING'] = @test_user.sns_link_key + ".notice"
    get :show

    # puts @response.body
    res = RSS::Parser.parse(@response.body)

    item = res.channel.items.shift
    assert_equal "トモダチ依頼が1件あります。", item.title

    if SnsLinkageExtension.instance.extension_enabled?(:community)
      item = res.channel.items.shift
      assert_equal "コミュニティ参加依頼が1件あります。", item.title
      assert_not_nil item.link
      assert_not_nil item.author
      assert_nil item.category
    end

    item = res.channel.items.shift
    assert_equal "新着メッセージが1件あります。", item.title
    assert_not_nil item.link
    assert_not_nil item.author
    assert_nil item.category
  end

  # 最新情報表示
  def test_news
    if SnsLinkageExtension.instance.extension_enabled?(:blog)
      friend = User.make
      @test_user.friend!(friend)
      friend_entry = BlogEntry.make(:user => friend)
      entry = BlogEntry.make(:user => @test_user, :blog_category => BlogCategory.make)
      comment = BlogComment.make(:blog_entry => entry)
    end
    if SnsLinkageExtension.instance.extension_enabled?(:community)
      com = Community.make
      com.members << @test_user
      topic = CommunityTopic.make(:community => com)
    end

    @request.env['QUERY_STRING'] = @test_user.sns_link_key + ".news"
    get :show

    # puts @response.body
    res = RSS::Parser.parse(@response.body)

    if SnsLinkageExtension.instance.extension_enabled?(:blog)
      item = res.channel.items.shift
      assert_equal friend_entry.title, item.title
      assert_equal blog_entry_url(friend_entry), item.link
      assert_equal friend_entry.user.name, item.author
      assert_equal "トモダチ最新ブログ", item.category.content

      item = res.channel.items.shift
      assert_equal entry.title, item.title
      assert_equal blog_entry_url(entry), item.link
      assert_equal comment.user.name, item.author
      assert_equal "最新マイブログコメント", item.category.content
    end

    if SnsLinkageExtension.instance.extension_enabled?(:community)
      item = res.channel.items.shift
      assert_equal topic.title, item.title
      assert_equal community_topic_url(com, topic), item.link
      assert_equal topic.author.name, item.author
      assert_equal "コミュニティ最新書き込み", item.category.content
    end
  end

  # 不正なURLを指定
  def test_invalid_request
    get :show
    assert_equal "", @response.body

    @request.env['QUERY_STRING'] = @test_user.sns_link_key + ".invalid"
    get :show
    assert_equal "", @response.body

    @request.env['QUERY_STRING'] = "invalid" + ".news"
    get :show
    assert_equal "", @response.body
  end
end

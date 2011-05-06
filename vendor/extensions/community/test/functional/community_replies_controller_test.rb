require File.dirname(__FILE__) + '/../test_helper'

# コミュニティスレッドへの返信管理テスト
class CommunityRepliesControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # イベントへの返信画面の表示
  def test_new_for_event
    reply_attributes = valid_community_reply_plan(CommunityEvent)

    get :new, :community_event_id => reply_attributes[:thread_id]

    assert_response :success
    assert_template 'community_replies/form'
    assert_kind_of CommunityReply, assigns(:community_reply)
  end

  # イベントへの返信確認画面表示
  def test_confirm_before_create_for_event
    reply_attributes = valid_community_reply_plan(CommunityEvent)

    assert_no_difference(['CommunityReply.count']) do
      post :confirm_before_create, :community_event_id => reply_attributes[:thread_id],
           :community_reply => reply_attributes
    end

    assert_response :success
    assert_template 'community_replies/confirm'
    assert_equal true, assigns(:community_reply).valid?
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    reply_attributes = valid_community_reply_plan(CommunityEvent)

    post :confirm_before_create, :community_reply => reply_attributes,
         :community_event_id => reply_attributes[:thread_id],
         :clear => "Clear"

    assert_response :redirect
    assert_redirected_to new_community_event_reply_path(:community_event_id => reply_attributes[:thread_id])
  end

  # イベントへの返信を作成
  def test_create_community_reply_for_event
    reply_attributes = valid_community_reply_plan(CommunityEvent)

    assert_difference(['CommunityReply.count']) do
      post :create, :community_reply => reply_attributes,
           :community_event_id => reply_attributes[:thread_id]
    end

    @community_reply = CommunityReply.last
    assert_equal reply_attributes[:title], @community_reply.title
    assert_equal reply_attributes[:content], @community_reply.content

    args = {
      :id => @community_reply.id,
      :community_event_id => reply_attributes[:thread_id],
      :path => "community_event_path",
      :thread_id => reply_attributes[:thread_id],
      :community_id => @community_reply.thread.community.id
    }

    assert_redirected_to complete_after_create_community_event_reply_path(args)
  end

  # 非ログインユーザがイベントへの返信を作成
  def test_anonymous_create_community_reply_for_event
    logout

    reply_attributes = valid_community_reply_plan(CommunityEvent)

    assert_no_difference(['CommunityReply.count']) do
      post :create, :community_reply => reply_attributes,
                    :community_event_id => reply_attributes[:thread_id]
    end

    assert_redirected_to root_path
  end

  # コミュニティの非参加者がイベントへの返信を作成
  def test_not_member_create_community_reply_for_event
    reply_attributes = valid_community_reply_plan(CommunityEvent)
    @current_user.has_no_roles_for!(Community.find(reply_attributes[:community_id]))

    assert_no_difference(['CommunityReply.count']) do
      post :create, :community_reply => reply_attributes,
                    :community_event_id => reply_attributes[:thread_id]
    end

    assert_redirected_to root_path
  end

  # イベントへの参加を行う
  def test_entry_event
    # NO]TE:イベント作成時にそのユーザは参加者となるので、異なるユーザを作成して参加を行う
    logout
    reply_author = User.make
    login_as(reply_author)

    reply_attributes = valid_community_reply_plan(CommunityEvent)

    community = CommunityThread.find(reply_attributes[:thread_id]).community
    community.receive_application(reply_author)

    assert_difference(['CommunityReply.count', 'CommunityEventMember.count']) do
      post :create, :community_reply => reply_attributes,
           :community_event_id => reply_attributes[:thread_id],
           :event_member => "entry"
    end

    @community_reply = CommunityReply.last

    assert @community_reply.thread.participations?(reply_author)

    args = {
      :id => @community_reply.id,
      :community_event_id => reply_attributes[:thread_id],
      :path => "community_event_path",
      :thread_id => reply_attributes[:thread_id],
      :community_id => @community_reply.thread.community.id,
      :event_member => "entry"
    }

    assert_redirected_to complete_after_create_community_event_reply_path(args)

  end

  # イベントへの参加をキャンセルする
  def test_cancel_event
    # NO]TE:イベント作成者は外せないので、他のユーザでキャンセルする
    logout
    reply_author = User.make
    login_as(reply_author)

    reply_attributes = valid_community_reply_plan(CommunityEvent)

    event = CommunityThread.find(reply_attributes[:thread_id])
    event.community.receive_application(reply_author)
    event.participate_in(reply_author)

    assert_difference('CommunityReply.count') do
      assert_difference('CommunityEventMember.count', -1) do
        post :create, :community_reply => reply_attributes,
             :community_event_id => reply_attributes[:thread_id],
             :event_member => "cancel"
      end
    end
    @community_reply = CommunityReply.last

    assert !@community_reply.thread.participations?(reply_author)

    args = {
      :id => @community_reply.id,
      :community_event_id => reply_attributes[:thread_id],
      :path => "community_event_path",
      :thread_id => reply_attributes[:thread_id],
      :community_id => @community_reply.thread.community.id,
      :event_member => "cancel"
    }

    assert_redirected_to complete_after_create_community_event_reply_path(args)
  end

  # 登録データの作成キャンセル
  def test_create_community_reply_cancel
    reply_attributes = valid_community_reply_plan(CommunityEvent)

    assert_no_difference(['CommunityReply.count']) do
      post :create, :community_reply => reply_attributes,
           :community_event_id => reply_attributes[:thread_id],
           :cancel => "Cancel"
    end

    assert_not_nil assigns(:community_reply)
    assert_template 'community_replies/form'
  end

  # イベントへの返信の編集画面の表示
  def test_edit_for_event
    reply = set_reply(CommunityEvent)

    get :edit, :id => reply.id, :community_event_id => reply.thread.id

    assert_response :success
    assert_template 'community_replies/form'
    assert_kind_of CommunityReply, assigns(:community_reply)
  end

  # イベントへの返信の編集データ確認画面表示
  def test_confirm_before_update_for_event
    reply = set_reply(CommunityEvent, :author => @current_user)

    updated_values = {
      :title => "テストタイトル",
      :content => "テスト本文",
      :thread_id =>  reply.thread_id,
    }

    post(:confirm_before_update, :id => reply.id,
         :community_event_id => reply.thread_id,
         :community_reply => updated_values)

    assert_response :success
    assert_template 'community_replies/confirm'
    assert_equal true, assigns(:community_reply).valid?
  end

  # イベントへの返信の編集データ確認画面表示失敗
  def test_confirm_before_update_fail_for_event
    reply = set_reply(CommunityEvent, :author => @current_user)
    updated_values = {
      :title => "",
      :content => "テスト本文",
      :thread_id =>  reply.thread_id,
    }

    post(:confirm_before_update, :id => reply.id, :community_event_id => reply.thread.id,
         :community_reply => updated_values)

    assert_response :success
    assert_template 'community_replies/form'
    assert_equal false, assigns(:community_reply).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    reply = set_reply(CommunityEvent, :author => @current_user)

    post(:confirm_before_update, :id => reply.id,
         :community_event_id => reply.thread_id,
         :community_reply => CommunityReply.plan,
         :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_community_event_reply_path(:id => reply.id, :community_event_id => reply.thread.id)
  end

  # イベントへの返信のデータの更新
  def test_update_community_reply_for_event
    reply = set_reply(CommunityEvent, :author => @current_user)

    updated_values = {
      :title => "テストタイトル",
      :content => "テスト本文",
      :thread_id =>  reply.thread_id,
    }

    assert_no_difference(['CommunityReply.count']) do
      put :update, :id => reply.id, :community_reply => updated_values,
          :community_event_id => reply.thread.id
    end

    @community_reply = CommunityReply.last
    updated_values.each do |k, v|
      assert_equal v, @community_reply.send(k)
    end

    args = {
      :id => @community_reply.id,
      :community_event_id => @community_reply.thread.id,
      :path => "community_event_path",
      :thread_id => @community_reply.thread.id,
      :community_id => @community_reply.thread.community.id
    }

    assert_redirected_to complete_after_update_community_event_reply_path(args)
  end

  # 編集データの作成キャンセル
  def test_update_community_reply_cancel
    reply = set_reply(CommunityEvent, :author => @current_user)

    updated_values = {
      :title => "テストタイトル",
      :content => "テスト本文",
      :thread_id =>  reply.thread_id,
    }

    put :update, :id => reply.id, :community_reply => updated_values,
        :community_event_id => reply.thread.id, :cancel => "Cancel"

    assert_not_nil assigns(:community_reply)
    assert_template 'community_replies/form'
  end

  # イベントへの返信データの更新の失敗（バリデーション）
  def test_update_community_reply_fail_for_event
    reply = set_reply(CommunityEvent, :author => @current_user)

    updated_values = {
      :title => "",
      :content => "テスト本文",
      :thread_id =>  reply.thread_id,
    }

    assert_no_difference(['CommunityReply.count']) do
      put :update, :id => reply.id, :community_reply => updated_values,
          :community_event_id => reply.thread.id
    end

    assert_template 'community_replies/form'
  end

  # レコードの削除
  def test_destroy_community_reply
    reply = set_reply(CommunityEvent, :author => @current_user)
    assert_equal false, reply.deleted

    delete :destroy, :id => reply.id, :community_event_id => reply.thread.id

    assert_equal true, reply.reload.deleted
    assert_redirected_to send(reply.thread.kind.underscore + "_path", :community_id => reply.thread.community_id, :id => reply.thread.id)
  end

  # 返信文章を引用する
  def test_quote_content
    author = User.make(:name => "author")
    thread = CommunityTopic.make(:content => "content\n\ncontent",
                                 :author => author)
    reply = CommunityReply.new(:thread => thread,
                               :content => "")
    expected_quote_content = "authorさんの発言\n> content\n> \n> content"

    post :quote_content, :community_reply => {:thread_id => thread.id,
                                              :content => ""}

    assert_equal expected_quote_content, assigns(:community_reply).content
  end

  # 匿名ユーザへのaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_anonymous_by_visibility
    logout
    community = Community.make
    topic = CommunityTopic.make(:community => community)
    reply = CommunityReply.make(:community => community, :thread => topic)

    get :show, :id => reply.id, :community_topic_id => topic.id

    assert_response :success
    assert_template "community_replies/show"

    [:member, :approval_required_and_private, :secret].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      assert_raise Acl9::AccessDenied do
        get :show, :id => reply.id, :community_topic_id => topic.id
      end
    end
  end

  # ログインユーザへのaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_logged_in_user_by_visibility
    community = Community.make
    topic = CommunityTopic.make(:community => community)
    reply = CommunityReply.make(:community => community, :thread => topic)

    [:public, :member].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      get :show, :id => reply.id, :community_topic_id => topic.id
      assert_response :success
      assert_template "community_replies/show"
    end

    [:approval_required_and_private, :secret].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      assert_raise Acl9::AccessDenied do
        get :show, :id => reply.id, :community_topic_id => topic.id
      end
    end
  end

  # コミュニティメンバーへのwaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_member_by_visibility
    community = set_community_and_has_role("community_general")
    topic = CommunityTopic.make(:community => community)
    reply = CommunityReply.make(:community => community, :thread => topic)

    Community::APPROVALS_AND_VISIBILITIES.each_value do |v|
      community.update_attributes!(:participation_and_visibility => v)
      get :show, :id => reply.id, :community_topic_id => topic.id
      assert_response :success
      assert_template "community_replies/show"
    end
  end


  # 自分が作成したもの、もしくは副管理人か管理人でなければ編集・削除できないことをテスト
  def test_verify_reply_editable_or_destroyable
    community = set_community_and_has_role("community_general")
    topic = CommunityTopic.make(:community => community)
    reply = CommunityReply.make(:community => community, :thread => topic)

    post :confirm_before_update, :id => reply.id, :community_topic_id => topic.id, :community_reply => CommunityReply.plan
    assert_response :redirect
    assert_redirected_to root_path
    delete :destroy, :id => reply.id, :community_topic_id => topic.id
    assert_response :redirect
    assert_redirected_to root_path

    reply = CommunityReply.make(:community => community, :thread => topic, :author => @current_user)
    post :confirm_before_update, :id => reply.id, :community_topic_id => topic.id, :community_reply => CommunityReply.plan
    assert_response :success
    assert_template "community_replies/confirm"
    delete :destroy, :id => reply.id, :community_topic_id => topic.id
    assert_response :redirect
    assert_redirected_to  community_topic_path(:id => topic.id, :community_id => community.id)

    ["community_sub_admin", "community_admin"].each do |role|
      @current_user.has_no_roles_for!(community)
      @current_user.has_role!(role, community)
      reply = CommunityReply.make(:community => community, :thread => topic)
      post :confirm_before_update, :id => reply.id, :community_topic_id => topic.id, :community_reply => CommunityReply.plan
      assert_response :success
      assert_template "community_replies/confirm"

      delete :destroy, :id => reply.id, :community_topic_id => topic.id
      assert_response :redirect
      assert_redirected_to  community_topic_path(:id => topic.id, :community_id => community.id)
    end
  end

  # 論理削除フラグがたっているものは表示できないことをテスト
  def test_access_denied_on_deleted_reply
    community = set_community_and_has_role("community_general")
    topic = CommunityTopic.make(:community => community)
    reply_deleted = CommunityReply.make(:community => community, :thread => topic, :deleted => true)

    assert_raise Acl9::AccessDenied do
      get :show, :id => reply_deleted.id, :community_topic_id => topic.id
    end
  end

  # Adobe Airクライアントから自分が属しているコミュニティのコメントの取得要求を受けるAPIのテスト
  def test_get_comment
    # NOTE: fixturesに、公認（管理人）が存在するので、current_userは作成された時点でそこに所属してしまうので、ここで削除する
    Community.destroy_all

    # コミュニティを40作成
    community_numbers = 40
    communities = Array.new(community_numbers){ set_community_and_has_role }

    # それぞれにトピックを作成し、さらにそのトピックに返信を作成
    communities.each do |c|
      topic = CommunityTopic.make(:community => c, :author => User.make)
      CommunityReply.make(:thread => topic,
                          :author => User.make)
    end

    get :index, :format => "atom"

    comments = assigns(:comments)
    assert_equal community_numbers * 2, comments.total_entries
    assert_feed(comments, "コミュニティコメント一覧", :user)
    comments.each_with_index{ |c, i| assert_entry(c, i + 1) }
    assert_response 200
  end

  # Adobe Airクライアントから特定のコミュニティのコメントの取得要求を受けるAPIのテスト
  def test_get_comment_specified_community
    topic_numbers = 20
    community = set_community_and_has_role
    topic_numbers.times do
      topic = CommunityTopic.make(:community => community, :author => User.make)
      CommunityReply.make(:thread => topic,
                          :author => User.make)
    end

    get :index, :format => "atom", :community_id => community.id

    comments = assigns(:comments)
    assert_equal topic_numbers * 2, comments.total_entries
    assert_feed(comments, community.name, :community, :community_id => community.id)
    comments.each_with_index{ |c, i| assert_entry(c, i + 1) }
    assert_response 200
  end

  # Adobe Airクライアントから特定のトピックのコメントの取得要求を受けるAPIのテスト
  def test_get_comment_specified_topic
    comment_number = 50
    community = set_community_and_has_role
    topic = CommunityTopic.make(:community => community, :author => User.make)
    comment_number.times do
      CommunityReply.make(:thread => topic,
                          :author => User.make)
    end

    get :index, :format => "atom", :topic_id => topic.id

    comments = assigns(:comments)
    assert_equal comment_number, comments.total_entries
    assert_feed(comments, topic.title, :topic, :topic_id => topic.id)
    comments.each_with_index{ |c, i| assert_entry(c, i + 1) }
    assert_response 200
  end

  # Adobe Airクライアントからxmlをサーバへ送信して、トピックへのコメントの投稿を受けるAPIのテスト
  def test_post_comment_to_topic
    @request.env['RAW_POST_DATA'] = <<-EOS
      <?xml version="1.0" encoding='utf-8'?>
      <entry xmlns="http://www.w3.org/2005/Atom">
        <title>Some Title</title>
        <content type="text">Some Reply</content>
        <updated>2008-01-01T00:00:00+09:00</updated>
     </entry>
    EOS
    community = set_community_and_has_role
    topic = CommunityTopic.make(:community => community)

    assert_difference "CommunityReply.count" do
      post :create, :format => "atom", :topic_id => topic.id
    end

    reply = assigns(:reply)
    assert_equal "Some Title", reply.title
    assert_equal "Some Reply", reply.content
    assert_equal topic.id, reply.thread.id
    assert_entry(reply)
    assert_response 201
  end

  # Adobe Airクライアントからxmlをサーバへ送信して、トピックの返信へのコメントの投稿を受けるテスト
  def test_post_comment_to_reply
    @request.env['RAW_POST_DATA'] = <<-EOS
      <?xml version="1.0" encoding='utf-8'?>
      <entry xmlns="http://www.w3.org/2005/Atom">
        <title>Some Title</title>
        <content type="text">Some Reply</content>
        <updated>2008-01-01T00:00:00+09:00</updated>
      </entry>
    EOS
    community = set_community_and_has_role
    topic = CommunityTopic.make(:community => community)
    parent_reply = CommunityReply.make(:thread => topic, :community => community)

    assert_difference "CommunityReply.count" do
      post :create, :format => "atom", :parent_id => parent_reply.id
    end

    reply = assigns(:reply)
    assert_equal "Some Title", reply.title
    assert_equal "Some Reply", reply.content
    assert_equal topic.id, reply.thread.id
    assert_equal parent_reply.id, reply.parent.id
    assert_entry(reply)
    assert_equal "http://#{@request.host}/community_comments/#{reply.id}.atom", @response.headers["Location"]
    assert_response 201
  end

  private

  # 返信作成、編集ができるようにcommunityやthreadを作成し、replyの属性と属性値のハッシュを返す
  def valid_community_reply_plan(thread_class, attrs = {})
    community = set_community_and_has_role("community_general")
    thread = thread_class.make(:community => community, :author => @current_user)
    plan = CommunityReply.plan(:community => community,
                               :thread => thread)

  end

  def set_reply(thread_class, attrs = { })
    community = Community.make
    thread = thread_class.make(:community => community)
    CommunityReply.make({:thread => thread}.merge(attrs))
  end

  # AdobeAir クライアントへのレスポンスのentryを除いたfeed以下の要素をチェックする
  def assert_feed(comments, title, type, params={})
    body = @response.body
    doc = REXML::Document.new body
    feed_element = doc.root.get_elements("/feed").first

    assert_equal "tag:#{@request.host},2009:community-replies-#{@current_user.id}", feed_element.get_text("id").to_s
    assert_equal title, feed_element.get_text("title").to_s
    assert !feed_element.get_elements("updated").blank?

    assert_link_for_feed(type, comments, feed_element, params)
  end

  # AdobeAir クライアントへのレスポンスのentry以下の要素をチェックする
  def assert_entry(comment, entry_number = 1)
    reply_id = comment.object_type == "Topic" ? nil : comment.id
    topic_id = comment.object_type == "Topic" ? comment.id : comment.thread.id
    community_id = comment.object_type == "Topic" ? comment.community_id : comment.thread.community_id

    body = @response.body
    doc = REXML::Document.new body
    xpath = (doc.root.name == "feed" ? "/feed/entry[#{entry_number}]" : "/entry[#{entry_number}]")
    entry_element = doc.root.get_elements(xpath).first

    # link要素のチェック
    assert_link_for_entry(entry_element, reply_id, topic_id, community_id)

    # id要素のチェック
    assert_equal comment.id, entry_element.get_text("id").to_s.to_i

    # title要素のチェック
    assert_equal comment.title, entry_element.get_text("title").to_s

    # author要素のチェック
    # NOTE: 名前をランダムで生成しているため、アポストロフィーが含まれている場合、xml中で&apos;にエスケープされている
    # そのため、ここではauthorの名前に含まれるアポストロフィーを置換処理を行ってから比較する
    name = comment.author.name.gsub(/'/, "&apos;")
    assert_equal name, entry_element.get_text("author/name").to_s

    # 拡張mars要素のチェック
    assert_equal Community.find(community_id).name, entry_element.get_text("mars:community").to_s
    assert_equal CommunityTopic.find(topic_id).title, entry_element.get_text("mars:topic").to_s

    # content要素のチェック
    assert_equal comment.content, entry_element.get_text("content").to_s

    # updated要素のチェック
    assert_equal comment.created_at.xmlschema, entry_element.get_text("updated").to_s
  end

  # atom feedのlink要素のチェック
  # ただし、ユーザ指定、コミュニティ指定、トピック指定でそれぞれhref属性値が異なる
  def assert_link_for_feed(type, comments, feed_element, params = { })
    expected_links_attributes = []
    expected_links_attributes << {:rel => "user_timeline", :href => href_attribute_for_feed(type)}
    expected_links_attributes << {:rel => "first", :href => href_attribute_for_feed(type, params.merge(:count => comments.per_page, :page => 1))}
    if comments.previous_page
      expected_links_attributes << {:rel => "previous", :href => href_attribute_for_feed(type, params.merge(:count => comments.per_page, :page => comments.previous_page))}
    end
    expected_links_attributes << {:rel => "self", :href => href_attribute_for_feed(type, params.merge(:count => comments.per_page, :page => comments.current_page))}
    if comments.next_page
      expected_links_attributes << {:rel => "next", :href => href_attribute_for_feed(type, params.merge(:count => comments.per_page, :page => comments.next_page))}
    end
    expected_links_attributes << {:rel => "last", :href => href_attribute_for_feed(type, params.merge(:count => comments.per_page, :page => comments.total_pages))}

    feed_element.each_element("link") do |link_element|
      expected_link_attribute = expected_links_attributes.shift
      assert_equal expected_link_attribute[:rel], link_element.attributes["rel"]
      assert_equal expected_link_attribute[:href], link_element.attributes["href"]
    end
    assert_equal 0, expected_links_attributes.size
  end

  # atom entryのlink要素のチェック
  def assert_link_for_entry(entry_element, reply_id, topic_id, community_id)
    expected_links_attributes =
      [{:rel => "profile_image", :href => "http://#{@request.host}/themes/#{SnsConfig.master_record.sns_theme.name}/images/noface.gif"},
       {:rel => "community_timeline", :href => "http://#{@request.host}:#{@request.port}/communities/#{community_id}/community_comments.atom"},
       {:rel => "topic_timeline", :href => "http://#{@request.host}:#{@request.port}/community_topics/#{topic_id}/community_comments.atom"},
       {:rel => "reply_to_topic", :href => "http://#{@request.host}:#{@request.port}/community_topics/#{topic_id}/community_comments.atom"}]
    if reply_id
      # 一覧取得時に、コメントのモデルがCommunityReplyのとき
      expected_links_attributes <<  {:rel => "reply_to_comment", :href => "http://#{@request.host}:#{@request.port}/community_comments/#{reply_id}/community_comments.atom" }
    else
      # 一覧取得時に、コメントのモデルがCommunityTopicのとき
      # このときは、reply_to_topicのhref属性値と同じhref属性値を返す
      expected_links_attributes << {:rel => "reply_to_comment", :href => "http://#{@request.host}:#{@request.port}/community_topics/#{topic_id}/community_comments.atom"}
    end

    entry_element.each_element("link") do |link_element|
      expected_link_attribute = expected_links_attributes.shift
      assert_equal expected_link_attribute[:rel], link_element.attributes["rel"]
      assert_match expected_link_attribute[:href], link_element.attributes["href"]
    end
    assert_equal 0, expected_links_attributes.size
  end

  # atom feedのlink要素のhref属性値を返す
  def href_attribute_for_feed(type, params={})
    count = params[:count]; page = params[:page]
    return "http://#{@request.host}:#{@request.port}/community_comments.atom" if !count && !page
    case type
    when :user
      "http://#{@request.host}:#{@request.port}/community_comments.atom?count=#{count}&amp;page=#{page}"
    when :community
      "http://#{@request.host}:#{@request.port}/communities/#{params[:community_id]}/community_comments.atom?count=#{count}&amp;page=#{page}"
    when :topic
      "http://#{@request.host}:#{@request.port}/community_topics/#{params[:topic_id]}/community_comments.atom?count=#{count}&amp;page=#{page}"
    end
  end
end

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CommunitiesControllerTest < ActionController::TestCase

  def setup
    @current_user = User.make(:admin => true)
    login_as(@current_user)
  end

  # コミュニティ書き込み管理のテスト
  def test_wrote_administration_write_communities
    10.times do
      set_community_and_has_role
    end
    communities = Community.find(:all)

    per_page = 5
    page = 2

    # 条件なし
    get :wrote_administration_communities, :type => "write"

    assert_response :success
    assert_template 'admin/communities/wrote_administration_communities_write'
    assert_not_nil assigns(:communities)

    # 表示件数指定
    get :wrote_administration_communities, :per_page => per_page, :type => "write"

    expected_total_pages = (communities.count / per_page.to_f).ceil
    assert_response :success
    assert_equal expected_total_pages, assigns(:communities).total_pages
    assert_equal 1, assigns(:communities).current_page
    assert_equal per_page, assigns(:communities).size

    # ページ指定
    get :wrote_administration_communities, :page => page, :type => "write"

    assert_response :success
    assert_equal page, assigns(:communities).current_page

    # 表示件数、ページ指定
    get :wrote_administration_communities, :page => page, :per_page => per_page, :type => "write"
    expected_total_pages = (communities.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:communities).total_pages
    assert_equal page, assigns(:communities).current_page
    assert_equal per_page, assigns(:communities).size
  end

  # コミュニティファイル管理のテスト
  def test_wrote_administration_file_communities
    per_page = 5
    page = 2
    10.times do
      Community.make(:image => upload("#{RAILS_ROOT}/public/images/rails.png"))
    end

    communities = Community.find(:all, :conditions => ["image <> ? ", ''])

    # コミュニティファイル管理
    get :wrote_administration_communities, :type => "file"

    assert_response :success
    assert_template 'admin/communities/wrote_administration_communities_file'
    assert_not_nil assigns(:communities)

    # 表示件数指定

    get :wrote_administration_communities, :per_page => per_page, :type => "file"

    expected_total_pages = (communities.count / per_page.to_f).ceil
    assert_response :success
    assert_equal expected_total_pages, assigns(:communities).total_pages
    assert_equal 1, assigns(:communities).current_page
    assert_equal per_page, assigns(:communities).size

    # ページ指定
    get :wrote_administration_communities, :page => page, :type => "file"

    assert_response :success
    assert_equal page, assigns(:communities).current_page

    # 表示件数、ページ指定
    get :wrote_administration_communities, :page => page, :per_page => per_page, :type => "file"
    expected_total_pages = (communities.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:communities).total_pages
    assert_equal page, assigns(:communities).current_page
    assert_equal per_page, assigns(:communities).size

  end

  # コミュニティイベント書き込み管理のテスト
  def test_wrote_administration_write_community_events
    per_page = 5
    page = 2
    community = Community.make
    10.times do
      CommunityEvent.make(:community => community)
    end
    community_events = CommunityEvent.find(:all)

    # 条件なし
    get :wrote_administration_events, :type => "write"

    assert_response :success
    assert_template 'admin/communities/wrote_administration_events_write'
    assert_not_nil assigns(:community_events)

    # 表示件数指定
    get :wrote_administration_events, :per_page => per_page, :type => "write"

    expected_total_pages = (community_events.count / per_page.to_f).ceil
    assert_response :success
    assert_equal expected_total_pages, assigns(:community_events).total_pages
    assert_equal 1, assigns(:community_events).current_page
    assert_equal per_page, assigns(:community_events).size

    # ページ指定
    get :wrote_administration_events, :page => page, :type => "write"

    assert_response :success
    assert_equal page, assigns(:community_events).current_page

    # 表示件数、。ページ指定
    get :wrote_administration_events, :page => page, :per_page => per_page, :type => "write"
    expected_total_pages = (community_events.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:community_events).total_pages
    assert_equal page, assigns(:community_events).current_page
    assert_equal per_page, assigns(:community_events).size

  end

  # コミュニティイベントファイル管理のテスト
  def test_wrote_administration_file_community_events
    per_page = 5
    page = 2
    community = Community.make
    10.times do
      community_event = CommunityEvent.make(:community => community)
      CommunityThreadAttachment.make(:thread => community_event, :image => upload(("#{RAILS_ROOT}/public/images/rails.png")))
    end
    community_thread_attachments =
      CommunityThreadAttachment.find(:all,
                                     :include => :thread,
                                     :conditions => ['community_threads.type = ?', 'CommunityEvent'])


    # 条件なし
    get :wrote_administration_events, :type => "file"

    assert_response :success
    assert_template 'admin/communities/wrote_administration_events_file'
    assert_not_nil assigns(:community_thread_attachments)

    # 表示件数指定
    get :wrote_administration_events, :per_page => per_page, :type => "file"

    expected_total_pages = (community_thread_attachments.count / per_page.to_f).ceil
    assert_response :success
    assert_equal expected_total_pages, assigns(:community_thread_attachments).total_pages
    assert_equal 1, assigns(:community_thread_attachments).current_page
    assert_equal per_page, assigns(:community_thread_attachments).size

    # ページ指定
    get :wrote_administration_events, :page => page, :type => "file"

    assert_response :success
    assert_equal page, assigns(:community_thread_attachments).current_page

    # 表示件数、ページ指定
    get :wrote_administration_events, :page => page, :per_page => per_page, :type => "file"
    expected_total_pages = (community_thread_attachments.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:community_thread_attachments).total_pages
    assert_equal page, assigns(:community_thread_attachments).current_page
    assert_equal per_page, assigns(:community_thread_attachments).size


  end

  # コミュニティトピック書き込み管理のテスト
  def test_wrote_administration_write_community_topics
    page = 2
    per_page = 5
    community = Community.make
    5.times do
      CommunityEvent.make(:community => community)
    end
    5.times do
      CommunityTopic.make(:community => community)
    end

    community_topics = CommunityTopic.find_by_sql(CommunityTopic.topics_write_query)


    # 条件なし
    get :wrote_administration_topics, :type => "write"

    assert_response :success
    assert_template 'admin/communities/wrote_administration_topics_write'
    assert_not_nil assigns(:community_topics)

    # 表示件数指定
    get :wrote_administration_topics, :per_page => per_page, :type => "write"


    expected_total_pages = (community_topics.count / per_page.to_f).ceil
    assert_response :success
    assert_equal expected_total_pages, assigns(:community_topics).total_pages
    assert_equal 1, assigns(:community_topics).current_page
    assert_equal per_page, assigns(:community_topics).size

    # ページ指定
    get :wrote_administration_topics, :page => page, :type => "write"

    assert_response :success
    assert_equal page, assigns(:community_topics).current_page

    # 表示件数、ページ指定
    get :wrote_administration_topics, :page => page, :per_page => per_page, :type => "write"
    expected_total_pages = (community_topics.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:community_topics).total_pages
    assert_equal page, assigns(:community_topics).current_page
    assert_equal per_page, assigns(:community_topics).size

  end

  # コミュニティトピック書き込み管理のテスト
  def test_wrote_administration_file_community_topics
    page = 2
    per_page = 5
    community = Community.make
    5.times do
      community_event = CommunityEvent.make(:community => community)
      community_topic = CommunityTopic.make(:community => community)
      CommunityThreadAttachment.make(:thread => community_event, :image => upload(("#{RAILS_ROOT}/public/images/rails.png")))
      CommunityThreadAttachment.make(:thread => community_topic, :image => upload(("#{RAILS_ROOT}/public/images/rails.png")))
    end
    attachments = CommunityThreadAttachment.find_by_sql(CommunityThreadAttachment.topics_file_query)

    # 条件指定なし
    get :wrote_administration_topics, :type => "file"

    assert_response :success
    assert_template 'admin/communities/wrote_administration_topics_file'
    assert_not_nil assigns(:attachments)

    # 表示件数指定
    get :wrote_administration_topics, :per_page => per_page, :type => "file"

    expected_total_pages = (attachments.count / per_page.to_f).ceil
    assert_response :success
    assert_equal expected_total_pages, assigns(:attachments).total_pages
    assert_equal 1, assigns(:attachments).current_page
    assert_equal per_page, assigns(:attachments).size

    # ページ指定
    get :wrote_administration_topics, :page => page, :type => "file"

    assert_response :success
    assert_equal page, assigns(:attachments).current_page

    # 表示件数、ページ指定
    get :wrote_administration_topics, :page => page, :per_page => per_page, :type => "file"
    expected_total_pages = (attachments.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:attachments).total_pages
    assert_equal page, assigns(:attachments).current_page
    assert_equal per_page, assigns(:attachments).size

  end

  # コミュニティ変更画面
  def test_edit
    community = communities(:curry)

    get :edit, :id => community.id

    assert_response :success
    assert_template :"form"
  end

  # コミュニティ設定変更確認画面
  def test_confirm_before_update
    community =
      set_community_and_has_role(:community_category => community_categories(:music))

    updating_attributes = {
      :comment => "テストコミュニティ",
      :latitude => 42.123456,
      :longitude => 123.45678,
      :zoom => 7,
      :official => 0
    }

    current_attributes = Community.plan(:community_category => community_categories(:music))

    assert_no_difference "Community.count" do
      post :confirm_before_update,
           :id => community.id,
           :community => updating_attributes.merge(:image => upload("#{RAILS_ROOT}/public/images/rails.png"))
    end

    assert_response :success
    assert_template :"confirm"

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, assigns(:community).send(attribute)
    end

    assert File.exists?(assigns(:community).image)
  end

  # コミュニティ設定変更確認エラー
  def test_confirm_before_update_error
    community =  set_community_and_has_role(:community_category => community_categories(:music))

    updating_attributes = {
      :comment => nil,
      :latitude => 42.123456,
      :longitude => 123.45678,
      :zoom => 7,
      :official => 0
    }

    assert_no_difference "Community.count" do
      post :confirm_before_update,
           :id => community.id,
           :community => updating_attributes
    end

    assert !assigns(:community).valid?
    assert_template :"form"
  end

  #  コミュニティ設定変更後、コミュニティ設定変更完了画面
  def test_update
    community =  set_community_and_has_role(:community_category => community_categories(:music))

    updating_attributes = {
      :name => "コミュニティ名",
      :comment => "説明を変更" ,
      :visibility => 3 ,
      :topic_createable_admin_only => false ,
      :event_createable_admin_only => false ,
      :participation_notice => true
      }
    current_attributes = Community.plan(:community_category => community_categories(:music))

    assert_no_difference "Community.count" do
      put :update, :id => community.id, :community => updating_attributes
    end

    community.reload
    assert_response :redirect
    assert_redirected_to complete_after_update_admin_community_path(community.id)
    assert "修正完了いたしました", assigns(:message)

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, community.send(attribute)
    end
  end

  #  コミュニティ設定変更エラー
  def test_update_error
    community = communities(:curry)
    updating_attributes = {
      :name => nil
      }

    assert_no_difference "Community.count" do
      put :update, :id => community.id, :community => updating_attributes
    end

    assert !assigns(:community).valid?
    assert_template :"form"

  end

  # コミュニティ削除確認画面
  def test_confirm_before_destroy
    community = set_community_and_has_role(:image => upload("#{RAILS_ROOT}/public/images/rails.png"))

    post :confirm_before_destroy, :id => community.id

    assert_equal community, assigns(:community)
    assert_template :"confirm_before_destroy"

  end

  # コミュニティ削除
  def test_destroy
    community = set_community_and_has_role

     assert_difference "Community.count", -1 do
      delete :destroy, :id => community.id
    end

    assert_redirected_to complete_after_destroy_new_admin_community_path
  end

  # コミュニティ添付削除
  def test_community_file_destroy
    community = set_community_and_has_role(:image => upload("#{RAILS_ROOT}/public/images/rails.png"))
    assert community.image

    assert_no_difference "Community.count" do
      delete :community_file_destroy, :id => community.id
    end

    assert_equal nil, assigns(:community).image
    assert_redirected_to wrote_administration_communities_admin_communities_path(:type => 'file')
  end

  # コミュニティイベント添付削除
  def test_community_event_file_destroy
    community = Community.make
    community_event = CommunityEvent.make(:community => community)
    community_thread_attachment = CommunityThreadAttachment.make(:thread => community_event, :image => upload("#{RAILS_ROOT}/public/images/rails.png"))

    assert_difference 'CommunityThreadAttachment.count', -1 do
      delete :community_event_file_destroy, :id => community_thread_attachment.id
    end
    assert_redirected_to wrote_administration_events_admin_communities_path(:type => 'file')
  end

  # コミュニティトピック添付削除
  def test_community_thread_file_destroy
    community = Community.make
    community_event = CommunityEvent.make(:community => community)
    community_thread_attachment = CommunityThreadAttachment.make(:thread => community_event, :image => upload("#{RAILS_ROOT}/public/images/rails.png"))


    assert_difference 'CommunityThreadAttachment.count', -1 do
      delete :community_thread_file_destroy, :id => community_thread_attachment.id
    end
    assert_redirected_to wrote_administration_topics_admin_communities_path(:type => 'file')
  end

  # コミュニティトピック返信の添付削除
  def test_community_reply_file_destroy
    community_event = CommunityEvent.make
    community_reply = CommunityReply.make(:thread => community_event)
    community_thread_reply_attachment =
      CommunityReplyAttachment.make(:position => 1, :reply => community_reply, :image => upload("#{RAILS_ROOT}/public/images/rails.png"))

    assert_difference 'CommunityReplyAttachment.count', -1 do
      delete :community_reply_file_destroy, :id => community_thread_reply_attachment.id
    end
    assert_redirected_to wrote_administration_topics_admin_communities_path(:type => 'file')
  end

  # 公認化初期処理のテスト
  # 公認コミュニティ（全員）のとき
  def test_initialization_official_type_all_member
    User.destroy_all("id != #{@current_user.id}")

    active_user = User.make(:approval_state => "active")
    pending_user = User.make(:approval_state => "pending")
    pause_user = User.make(:approval_state => "pause")

    community = set_community_and_has_role(:official => Community::OFFICIALS[:all_member])

    updating_attributes = {
      :name => "コミュニティ名", :comment => "説明を変更" ,
      :topic_createable_admin_only => false , :event_createable_admin_only => false ,
      :participation_notice => true}

    assert_difference "CommunityMembership.count", 2 do
      put :update, :id => community.id, :initialization_official => "1", :community => updating_attributes
    end

    community.reload
    assert community.member?(active_user)
    assert community.member?(pending_user)
    assert !community.member?(pause_user)

    assert_response :redirect
    assert_redirected_to complete_after_update_admin_community_path(community.id)
    assert "修正完了いたしました", assigns(:message)
  end

  # 公認化初期処理のテスト
  # 公認コミュニティ（管理人）のとき
  def test_initialization_official_type_admin_only
    User.destroy_all("id != #{@current_user.id}")

    community = set_community_and_has_role(:official => Community::OFFICIALS[:admin_only])

    updating_attributes = {
      :name => "コミュニティ名", :comment => "説明を変更" ,
      :topic_createable_admin_only => false , :event_createable_admin_only => false ,
      :participation_notice => true}

    # NOTE: pendingの状態を作るため
    SnsConfig.master_record.update_attributes!(:approval_type => SnsConfig::APPROVAL_TYPES[:approved_by_administrator])

    active_user = User.make(:approval_state => "active")
    pending_user = User.make(:approval_state => "pending")
    pause_user = User.make(:approval_state => "pause")

    [active_user, pending_user, pause_user].each do |u|
      set_community_and_has_role(u)
    end

    assert_difference "CommunityMembership.count" do
      put :update, :id => community.id, :initialization_official => "1", :community => updating_attributes
    end

    community.reload
    assert community.member?(active_user)
    assert !community.member?(pending_user)
    assert !community.member?(pause_user)

    assert_response :redirect
    assert_redirected_to complete_after_update_admin_community_path(community.id)
    assert "修正完了いたしました", assigns(:message)
  end
end

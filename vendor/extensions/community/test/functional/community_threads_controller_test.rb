require File.dirname(__FILE__) + '/../test_helper'

class CommunityThreadsControllerTest < ActionController::TestCase

  def setup
    @current_user ||= User.make
    login_as(@current_user)
    @community = set_community_and_has_role
    set_threads_for_search
  end

  # トピック検索画面へのアクセス
  # 何も指定していないときは、トピックとイベントが全て表示される
  def test_search
    get :search, :community_id => @community.id

    threads = assigns(:community_threads)
    assert_equal 2, threads.count
    assert threads.any?{|t| t.kind == "CommunityTopic"}
    assert threads.any?{|t| t.kind == "CommunityEvent"}

    assert_response :success
    assert_template 'community_threads/search'
  end

  # キーワードがヒットする検索
  def test_search_when_keyword_hit
    get :search, :community_id => @community.id, :keyword => "titl"

    threads = assigns(:community_threads)
    assert_equal 2, threads.count
    assert threads.any?{|t| t.kind == "CommunityTopic"}
    assert threads.any?{|t| t.kind == "CommunityEvent"}

    assert_response :success
    assert_template 'community_threads/search'
  end

  # キーワードがヒットしない検索
  def test_search_when_keyword_no_hit
    get :search, :community_id => @community.id, :keyword => "no hit"

    threads = assigns(:community_threads)
    assert_equal 0, threads.count

    assert_response :success
    assert_template 'community_threads/search'
  end

  # 全種類取得する検索
  def test_search_with_all_types
    get :search, :community_id => @community.id,
        :types => %w(CommunityTopic CommunityEvent CommunityMarker)

    threads = assigns(:community_threads)
    assert_equal 3, threads.count
    assert threads.any?{|t| t.kind == "CommunityTopic"}
    assert threads.any?{|t| t.kind == "CommunityEvent"}
    assert threads.any?{|t| t.kind == "CommunityMarker"}

    assert_response :success
    assert_template 'community_threads/search'
  end

  # トピックツリー画面
  # あるコミュニティのcommunity_topicとcommunity_eventが取得できることを確認する
  def test_show_comment_tree
    community = Community.make
    CommunityEvent.make(:community => community, :created_at => Time.now - 1)
    CommunityMarker.make(:community => community, :created_at => Time.now)
    CommunityTopic.make(:community => community, :created_at => Time.now + 1)

    get :show_comment_tree, :community_id => community.id

    threads = assigns(:community_threads)
    assert_equal 2, threads.size
    assert threads.any?{|t| t.kind == "CommunityTopic"}
    assert threads.any?{|t| t.kind == "CommunityEvent"}

    assert_response :success
    assert_template "community_threads/show_comment_tree"
  end

  # トピックツリー画面
  # 特定のスレッドにある信をツリー表示する画面
  def test_show_comment_tree_specified_thread
    community = Community.make
    thread = CommunityEvent.make(:community => community)

    get :show_comment_tree_specified_thread, :id => thread.id,
        :community_id => community.id

    assert_equal thread.id, assigns(:community_thread).id

    assert_response :success
    assert_template "community_threads/show_comment_tree_specified_thread"
  end


  # ログアウトしている状態でのトピック検索へのアクセステスト
  def test_access_index_without_login
    logout

    community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_private])
    assert_raise Acl9::AccessDenied do
      get :search, :community_id => community.id
    end

    community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:member])
    assert_raise Acl9::AccessDenied do
      get :search, :community_id => community.id
    end

    community = Community.make
    assert community.visibility_public?
    get :search, :community_id => community.id
    assert_response :success
    assert_template "community_threads/search"
  end

  # ログインしているが、コミュニティのメンバーでないときのトピック検索へのアクセステスト
  def test_access_index_with_login
    community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_private])
    assert_raise Acl9::AccessDenied do
      get :search, :community_id => community.id
    end

    community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:member])
    get :search, :community_id => community.id
    assert_response :success
    assert_template "community_threads/search"

    community = Community.make
    get :search, :community_id => community.id
    assert_response :success
    assert_template "community_threads/search"
  end

  # コミュニティメンバーであるときのトピック検索へのアクセステスト
  def test_access_index_with_community_member
    Community::APPROVALS_AND_VISIBILITIES.values.each do |participation_and_visibility|
      community =
        set_community_and_has_role("community_general",
                                   :participation_and_visibility => participation_and_visibility)
      get :search, :community_id => community.id
    assert_response :success
    assert_template "community_threads/search"
    end
  end

  private

  # 検索用スレッド作成メソッド
  # トピック、イベント、マーカーそれぞれ1つずつ作成する
  def set_threads_for_search
    attr = {:community => @community, :title => "title", :content => "content"}
    CommunityTopic.make(attr.merge(:created_at => Time.now.tomorrow))
    CommunityEvent.make(attr.merge(:created_at => Time.now))
    CommunityMarker.make(attr.merge(:created_at => Time.now.yesterday))
  end
end

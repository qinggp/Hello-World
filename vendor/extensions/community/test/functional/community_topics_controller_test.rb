require File.dirname(__FILE__) + '/../test_helper'

# コミュニティのトピック管理テスト
class CommunityTopicsControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # 登録画面の表示
  def test_new
    community = set_community_and_has_role

    get :new, :community_id => community

    assert_response :success
    assert_template 'community_topics/form'
    assert_kind_of CommunityTopic, assigns(:community_topic)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    attributes = valid_community_topic_plan

    assert_no_difference(['CommunityTopic.count']) do
      post :confirm_before_create, :community_id => attributes[:community_id],
           :community_topic => attributes
    end

    assert_response :success
    assert_template 'community_topics/confirm'
    community_topic = assigns(:community_topic)

    attributes.each do |key, value|
      assert_equal value, community_topic.send(key)
    end
  end

  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    community = set_community_and_has_role

    attributes = {:title => "test_title", :content => ""}

    assert_no_difference(['CommunityTopic.count']) do
      post :confirm_before_create, :community_topic => attributes,
           :community_id => community.id
    end

    assert_response :success
    assert_template 'community_topics/form'
    assert_equal false, assigns(:community_topic).valid?
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    community = set_community_and_has_role

    post :confirm_before_create, :community_topic => {}, :clear => "Clear",
         :community_id => community.id

    assert_response :redirect
    assert_redirected_to new_community_topic_path
  end

  # 登録データの作成
  def test_create_community_topic
    attributes = valid_community_topic_plan

    assert_difference(['CommunityTopic.count']) do
      post :create, :community_topic => attributes,
           :community_id => attributes[:community_id]
    end

    community_topic = assigns(:community_topic)

    attributes.each do |key, value|
      assert_equal value, community_topic.send(key)
    end
    assert_redirected_to complete_after_create_community_topic_path(:id => community_topic.id, :community_id => community_topic.community.id)
  end

  # 登録データの作成キャンセル
  def test_create_community_topic_cancel
    community = set_community_and_has_role

    assert_no_difference(['CommunityTopic.count']) do
      post :create, :community_topic => CommunityTopic.plan, :cancel => "Cancel",
           :community_id => community.id
    end

    assert_not_nil assigns(:community_topic)
    assert_template 'community_topics/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_community_topic_fail
    community = set_community_and_has_role

    attributes = {:title => "test_title", :content => ""}

    assert_no_difference(['CommunityTopic.count']) do
      post :create, :community_topic => attributes,
           :community_id => community.id
    end

    assert_template 'community_topics/form'
  end

  # 詳細画面の表示
  def test_show_community_topic
    community_topic = CommunityTopic.make(:community => Community.make)

    get :show, :id => community_topic.id,
        :community_id => community_topic.community.id

    assert_response :success
    assert_template 'community_topics/show'
    assert_kind_of CommunityTopic, assigns(:community_topic)
  end

  # 編集画面の表示
  def test_edit
    topic = set_community_topic

    get :edit, :id => topic.id, :community_id => topic.community_id

    assert_response :success
    assert_template 'community_topics/form'
    assert_kind_of CommunityTopic, assigns(:community_topic)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    topic = set_community_topic

    post(:confirm_before_update, :id => topic.id,
         :community_topic => topic.attributes,
         :community_id => topic.community_id)

    assert_response :success
    assert_template 'community_topics/confirm'
    assert_equal true, assigns(:community_topic).valid?
  end

  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    topic = set_community_topic

    post(:confirm_before_update, :id => topic.id,
         :community_topic => {:title => ""},
         :community_id => topic.community_id)

    assert_response :success
    assert_template 'community_topics/form'
    assert_equal false, assigns(:community_topic).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    topic = set_community_topic

    post(:confirm_before_update, :id => topic.id,
         :community_topic => topic.attributes,
         :community_id => topic.community_id, :clear => 'Clear')

    assert_response :redirect
    assert_redirected_to edit_community_topic_path(:id => topic.id, :community_id => topic.community_id)
  end

  # 編集データの更新
  def test_update_community_topic
    topic = set_community_topic

    update_attributes = {
      :title => "new title",
      :content => "new content"
    }

    assert_no_difference(['CommunityTopic.count']) do
    put(:update, :id => topic.id,
        :community_topic => update_attributes,
        :community_id => topic.community_id)
    end

    updated_topic = assigns(:community_topic)

    update_attributes.each do |key, value|
      assert_equal value, updated_topic.send(key)
    end

    assert_redirected_to complete_after_update_community_topic_path(:id => updated_topic.id, :community_id => updated_topic.community_id)
  end

  # 編集データの作成キャンセル
  def test_update_community_topic_cancel
    topic = set_community_topic

    put(:update, :id => topic.id, :cancel => 'Cancel',
        :community_topic => topic.attributes,
        :community_id => topic.community_id)

    assert_not_nil assigns(:community_topic)
    assert_template 'community_topics/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_community_topic_fail
    topic = set_community_topic

    invalid_attributes = {:title => "" }

    put(:update, :id => topic.id,
        :community_topic => invalid_attributes,
        :community_id => topic.community_id)

    topic.reload

    invalid_attributes.each do |key, value|
      assert_not_equal value, topic.send(key)
    end

    assert_template 'community_topics/form'
  end

  # レコードの削除
  def test_destroy_community_topic
    topic = set_community_topic

    assert_difference('CommunityTopic.count', -1) do
      delete :destroy, :id => topic.id, :community_id => topic.community_id
    end

    assert_redirected_to search_community_threads_path(:community_id => topic.community_id)
  end

  # 匿名ユーザへのaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_anonymous_by_visibility
    logout
    community = Community.make
    topic = CommunityTopic.make(:community => community)

    get :show, :id => topic.id, :community_id => community.id

    assert_response :success
    assert_template "community_topics/show"

    [:member, :approval_required_and_private, :secret].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      assert_raise Acl9::AccessDenied do
        get :show, :id => topic.id, :community_id => community.id
      end
    end
  end

  # ログインユーザへのaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_logged_in_user_by_visibility
    community = Community.make
    topic = CommunityTopic.make(:community => community)

    [:public, :member].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      get :show, :id => topic.id, :community_id => community.id
      assert_response :success
      assert_template "community_topics/show"
    end

    [:approval_required_and_private, :secret].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      assert_raise Acl9::AccessDenied do
        get :show, :id => topic.id, :community_id => community.id
      end
    end
  end

  #  コミュニティメンバーへのwaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_member_by_visibility
    community = set_community_and_has_role("community_general")
    topic = CommunityTopic.make(:community => community)

    Community::APPROVALS_AND_VISIBILITIES.each_value do |v|
      community.update_attributes!(:participation_and_visibility => v)
      get :show, :id => topic.id, :community_id => community.id
      assert_response :success
      assert_template "community_topics/show"
    end
  end

  # メンバーでないユーザが、トピックを作成しようとするとトップページへ飛ばされる動作のテスト
  def test_verify_topic_createable_without_login
    community = Community.make(:topic_createable_admin_only => false)

    get :new, :community_id => community.id

    assert_redirected_to root_path

    community.update_attributes(:topic_createable_admin_only => true)

    get :new, :community_id => community.id

    assert_redirected_to root_path
  end

  # メンバーがトピックを作成しようとするとき、権限が無ければトップページへ飛ばされる動作のテスト
  def test_verify_topic_createable_for_member
    community = set_community_and_has_role("community_general",
                                           :topic_createable_admin_only => false)

    get :new, :community_id => community.id

    assert_response :success
    assert_template "form"

    community.update_attributes!(:topic_createable_admin_only => true)

    get :new, :community_id => community.id

    assert_redirected_to root_path
  end

  # 副管理人は、制限によらず常に作成できることをテスト
  def test_verify_topic_createable_for_sub_admin
    community = set_community_and_has_role("community_sub_admin",
                                           :topic_createable_admin_only => false)

    get :new, :community_id => community.id

    assert_response :success
    assert_template "form"

    community.update_attributes!(:topic_createable_admin_only => true)

    get :new, :community_id => community.id

    assert_response :success
    assert_template "form"
  end

  # 管理人は、制限によらず常に作成できることをテスト
  def test_verify_topic_createable_for_sub_admin
    community = set_community_and_has_role("community_admin",
                                           :topic_createable_admin_only => false)

    get :new, :community_id => community.id

    assert_response :success
    assert_template "form"

    community.update_attributes!(:topic_createable_admin_only => true)

    get :new, :community_id => community.id

    assert_response :success
    assert_template "form"
  end

  # 自分が作成したもの、もしくは副管理人か管理人でなければ編集・削除できないことをテスト
  def test_verify_topic_editable_or_destroyable
    community = set_community_and_has_role("community_general")
    topic = CommunityTopic.make(:community => community)

    get :edit, :id => topic.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to root_path
    delete :destroy, :id => topic.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to root_path

    topic = CommunityTopic.make(:community => community, :author => @current_user)
    get :edit, :id => topic.id, :community_id => community.id
    assert_response :success
    assert_template "community_topics/form"
    delete :destroy, :id => topic.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to  search_community_threads_path(:community_id => community.id)

    @current_user.has_no_roles_for!(community)
    @current_user.has_role!("community_sub_admin", community)
    topic = CommunityTopic.make(:community => community)
    get :edit, :id => topic.id, :community_id => community.id
    assert_response :success
    assert_template "community_topics/form"
    delete :destroy, :id => topic.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to  search_community_threads_path(:community_id => community.id)

    @current_user.has_no_roles_for!(community)
    @current_user.has_role!("community_admin", community)
    topic = CommunityTopic.make(:community => community)
    get :edit, :id => topic.id, :community_id => community.id
    assert_response :success
    assert_template "community_topics/form"
    delete :destroy, :id => topic.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to  search_community_threads_path(:community_id => community.id)
  end

  private

  def valid_community_topic_plan(attrs = {})
    community = set_community_and_has_role

    plan = CommunityTopic.plan(:community => community,
                               :author => @current_user).merge(attrs)
  end

  def set_community_topic(attrs = {})
    community = Community.make

    CommunityTopic.make({:community => community,
                         :author => @current_user}.merge(attrs))
  end
end

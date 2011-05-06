require File.dirname(__FILE__) + '/../test_helper'

# コミュニティイベント管理機能テスト
class CommunityEventsControllerTest < ActionController::TestCase

  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # 一覧画面の表示
  def _test_index
    community_event = CommunityEvent.make

    get :index, :id => community_event,
        :community_id => community_event.community

    assert_response :success
    assert_template 'community_events/index'
    assert_not_nil assigns(:community_events)
  end

  # 登録画面の表示
  def test_new
    community = set_community_and_has_role

    get :new, :community_id => community

    assert_response :success
    assert_template 'community_events/form'
    assert_kind_of CommunityEvent, assigns(:community_event)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    attributes = valid_community_event_plan

    assert_no_difference(['CommunityEvent.count']) do
      post :confirm_before_create, :community_id => attributes[:community_id],
           :community_event => attributes
    end

    assert_response :success
    assert_template 'community_events/confirm'
    community_event = assigns(:community_event)

    attributes.each do |key, value|
      assert_equal value, community_event.send(key)
    end
  end

  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    community = set_community_and_has_role

    attributes = {:title => "test_title", :content => ""}

    assert_no_difference(['CommunityEvent.count']) do
      post :confirm_before_create, :community_event => attributes,
           :community_id => community.id
    end

    assert_response :success
    assert_template 'community_events/form'
    assert_equal false, assigns(:community_event).valid?
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    community = set_community_and_has_role

    post :confirm_before_create, :community_event => {}, :clear => "Clear",
         :community_id => community.id

    assert_response :redirect
    assert_redirected_to new_community_event_path
  end

  # 登録データの作成
  def test_create_community_event
    attributes = valid_community_event_plan

    assert_difference(['CommunityEvent.count', 'CommunityEventMember.count']) do
      post :create, :community_event => attributes,
           :community_id => attributes[:community_id]
    end

    community_event = assigns(:community_event)

    attributes.each do |key, value|
      assert_equal value, community_event.send(key)
    end
    assert community_event.participations?(@current_user)
    assert_redirected_to complete_after_create_community_event_path(:id => community_event.id, :community_id => community_event.community.id)
  end

  # 登録データの作成キャンセル
  def test_create_community_event_cancel
    community = set_community_and_has_role

    assert_no_difference(['CommunityEvent.count']) do
      post :create, :community_event => CommunityEvent.plan, :cancel => "Cancel",
           :community_id => community.id
    end

    assert_not_nil assigns(:community_event)
    assert_template 'community_events/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_community_event_fail
    community = set_community_and_has_role

    attributes = {:title => "test_title", :content => ""}

    assert_no_difference(['CommunityEvent.count']) do
      post :create, :community_event => attributes,
           :community_id => community.id
    end

    assert_template 'community_events/form'
  end

  # 詳細画面の表示
  def test_show_community_event
    community_event = CommunityEvent.make(:community => Community.make)

    get :show, :id => community_event.id,
        :community_id => community_event.community.id

    assert_response :success
    assert_template 'community_events/show'
    assert_kind_of CommunityEvent, assigns(:community_event)
  end

  # 編集画面の表示
  def test_edit
    event = set_community_event

    get :edit, :id => event.id, :community_id => event.community_id

    assert_response :success
    assert_template 'community_events/form'
    assert_kind_of CommunityEvent, assigns(:community_event)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    event = set_community_event

    post(:confirm_before_update, :id => event.id,
         :community_event => event.attributes,
         :community_id => event.community_id)

    assert_response :success
    assert_template 'community_events/confirm'
    assert_equal true, assigns(:community_event).valid?
  end

  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    event = set_community_event

    post(:confirm_before_update, :id => event.id,
         :community_event => {:title => ""},
         :community_id => event.community_id)

    assert_response :success
    assert_template 'community_events/form'
    assert_equal false, assigns(:community_event).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    event = set_community_event

    post(:confirm_before_update, :id => event.id,
         :community_event => event.attributes,
         :community_id => event.community_id, :clear => 'Clear')

    assert_response :redirect
    assert_redirected_to edit_community_event_path(:id => event.id, :community_id => event.community_id)
  end

  # 編集データの更新
  def test_update_community_event
    event = set_community_event

    update_attributes = {
      :title => "new title",
      :content => "new content"
    }

    assert_no_difference(['CommunityEvent.count']) do
    put(:update, :id => event.id,
        :community_event => update_attributes,
        :community_id => event.community_id)
    end

    updated_event = assigns(:community_event)

    update_attributes.each do |key, value|
      assert_equal value, updated_event.send(key)
    end

    assert_redirected_to complete_after_update_community_event_path(:id => updated_event.id, :community_id => updated_event.community_id)
  end

  # 編集データの作成キャンセル
  def test_update_community_event_cancel
    event = set_community_event

    put(:update, :id => event.id, :cancel => 'Cancel',
        :community_event => event.attributes,
        :community_id => event.community_id)

    assert_not_nil assigns(:community_event)
    assert_template 'community_events/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_community_event_fail
    event = set_community_event

    invalid_attributes = {:title => "" }

    put(:update, :id => event.id,
        :community_event => invalid_attributes,
        :community_id => event.community_id)

    event.reload

    invalid_attributes.each do |key, value|
      assert_not_equal value, event.send(key)
    end

    assert_template 'community_events/form'
  end

  # レコードの削除
  def test_destroy_community_event
    event = set_community_event

    assert_difference('CommunityEvent.count', -1) do
      delete :destroy, :id => event.id, :community_id => event.community_id
    end

    assert_redirected_to search_community_threads_path(:community_id => event.community_id)
  end

  # 匿名ユーザへのaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_anonymous_by_visibility
    logout
    community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:public])
    event = CommunityEvent.make(:community => community)

    get :show, :id => event.id, :community_id => community.id

    assert_response :success
    assert_template "community_events/show"

    [:member, :approval_required_and_private, :secret].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      assert_raise Acl9::AccessDenied do
        get :show, :id => event.id, :community_id => community.id
      end
    end
  end

  # ログインユーザへのaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_logged_in_user_by_visibility
    community = Community.make
    event = CommunityEvent.make(:community => community)

    [:public, :approval_required_and_member].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      get :show, :id => event.id, :community_id => community.id
      assert_response :success
      assert_template "community_events/show"
    end

    [:approval_required_and_private, :secret].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      assert_raise Acl9::AccessDenied do
        get :show, :id => event.id, :community_id => community.id
      end
    end
  end

  #  コミュニティメンバーへのwaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_member_by_visibility
    community = set_community_and_has_role("community_general")
    event = CommunityEvent.make(:community => community)

    Community::APPROVALS_AND_VISIBILITIES.each_value do |v|
      community.update_attributes!(:participation_and_visibility => v)
      get :show, :id => event.id, :community_id => community.id
      assert_response :success
      assert_template "community_events/show"
    end
  end

  # イベントの公開制限がコミュニティ内のみになっているときに匿名ユーザへのaccess_controlテスト
  # 制限されるアクションのうち、showメソッドのみで確認する
  def test_access_control_anonymous_by_event_publiced
    logout

    community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:public])
    event = CommunityEvent.make(:community => community, :public => false)

    assert_raise Acl9::AccessDenied do
      get :show, :id => event.id, :community_id => community.id
    end
  end


  # イベントの公開制限がコミュニティ内のみになっているときにログインユーザへのaccess_controlテスト
  # 制限されるアクションのうち、showメソッドのみで確認する
  def test_access_control_logged_in_user_by_event_publiced
    community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:public])
    event = CommunityEvent.make(:community => community, :public => false)

    assert_raise Acl9::AccessDenied do
      get :show, :id => event.id, :community_id => community.id
    end
  end

  # イベントの公開制限がコミュニティ内のみになっているときにコミュニティメンバーへのaccess_controlテスト
  # 制限されるアクションのうち、showメソッドのみで確認する
  def test_access_control_logged_in_user_by_event_publiced
    community = set_community_and_has_role("community_general", :participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:public])
    event = CommunityEvent.make(:community => community, :public => false)

    get :show, :id => event.id, :community_id => community.id
    assert_response :success
    assert_template "community_events/show"
  end

  # メンバーでないユーザが、イベントを作成しようとするとトップページへ飛ばされる動作のテスト
  def test_verify_event_createable_without_login
    community = Community.make(:event_createable_admin_only => false)

    get :new, :community_id => community.id

    assert_redirected_to root_path

    community.update_attributes(:event_createable_admin_only => true)

    get :new, :community_id => community.id

    assert_redirected_to root_path
  end

  # メンバーがイベントを作成しようとするとき、権限が無ければトップページへ飛ばされる動作のテスト
  def test_verify_event_createable_for_member
    community = set_community_and_has_role("community_general",
                                           :event_createable_admin_only => false)

    get :new, :community_id => community.id

    assert_response :success
    assert_template "form"

    community.update_attributes!(:event_createable_admin_only => true)

    get :new, :community_id => community.id

    assert_redirected_to root_path
  end

  # 副管理人は、制限によらず常にイベントを作成できることをテスト
  def test_verify_event_createable_for_sub_admin
    community = set_community_and_has_role("community_sub_admin",
                                           :event_createable_admin_only => false)

    get :new, :community_id => community.id

    assert_response :success
    assert_template "form"

    community.update_attributes!(:event_createable_admin_only => true)

    get :new, :community_id => community.id

    assert_response :success
    assert_template "form"
  end

  # 管理人は、制限によらず常にイベントを作成できることをテスト
  def test_verify_event_createable_for_sub_admin
    community = set_community_and_has_role("community_admin",
                                           :event_createable_admin_only => false)

    get :new, :community_id => community.id

    assert_response :success
    assert_template "form"

    community.update_attributes!(:event_createable_admin_only => true)

    get :new, :community_id => community.id

    assert_response :success
    assert_template "form"
  end

  # 自分が作成したもの、もしくは副管理人か管理人でなければ編集・削除できないことをテスト
  def test_verify_event_editable_or_destroyable
    community = set_community_and_has_role("community_general")
    event = CommunityEvent.make(:community => community)

    get :edit, :id => event.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to root_path
    delete :destroy, :id => event.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to root_path

    event = CommunityEvent.make(:community => community, :author => @current_user)
    get :edit, :id => event.id, :community_id => community.id
    assert_response :success
    assert_template "community_events/form"
    delete :destroy, :id => event.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to  search_community_threads_path(:community_id => community.id)

    @current_user.has_no_roles_for!(community)
    @current_user.has_role!("community_sub_admin", community)
    event = CommunityEvent.make(:community => community)
    get :edit, :id => event.id, :community_id => community.id
    assert_response :success
    assert_template "community_events/form"
    delete :destroy, :id => event.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to  search_community_threads_path(:community_id => community.id)

    @current_user.has_no_roles_for!(community)
    @current_user.has_role!("community_admin", community)
    event = CommunityEvent.make(:community => community)
    get :edit, :id => event.id, :community_id => community.id
    assert_response :success
    assert_template "community_events/form"
    delete :destroy, :id => event.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to  search_community_threads_path(:community_id => community.id)
  end

  # コミュニティイベント参加者一覧表示画面テスト
  def test_show_members
    event = set_community_event
    3.times{ event.participations << User.make }

    get :show_members, :id => event.id, :community_id => event.community.id

    assert_equal 3, assigns(:members).size

    assert_response :success
    assert_template "show_members"
  end

  # ある特定の日付のイベント一覧表示画面テスト
  def test_list_on_date
    date = Date.civil(2020, 10, 10)

    3.times do
      CommunityEvent.make(:community => Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:public]),
                          :event_date => date,
                          :public => true)
    end

    get :list_on_date, :date => date.to_s

    events = assigns(:community_events)
    assert_equal 3, events.total_entries

    assert_response :success
    assert_template "list_on_date"
  end

  # ある特定の日付のイベント一覧表示画面テスト（非ログイン状態）
  def test_list_on_date_without_login
    logout

    date = Date.civil(2020, 10, 10)
    viewable_event = CommunityEvent.make(:community =>
                                         Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:public]),
                                         :event_date => date, :public => true)

    not_viewable_event = CommunityEvent.make(:community =>
                                         Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:member]),
                                         :event_date => date, :public => true)

    get :list_on_date, :date => date.to_s

    events = assigns(:community_events)
    assert_equal 1, events.total_entries
    assert_equal true, events.any?{|e| e.id == viewable_event.id }

    assert_response :success
    assert_template "list_on_date"
  end

  private

  def valid_community_event_plan(attrs = {})
    community = set_community_and_has_role

    plan = CommunityEvent.plan(:community => community,
                               :author => @current_user).merge(attrs)
  end

  def set_community_event(attrs = {})
    community = Community.make

    CommunityEvent.make({:community => community,
                         :author => @current_user}.merge(attrs))
  end
end

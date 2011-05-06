require File.dirname(__FILE__) + '/../test_helper'

# コミュニティマーカー管理テスト
class CommunityMarkersControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # 登録画面の表示
  def test_new
    community = set_community_and_has_role

    get :new, :community_id => community.id

    assert_response :success
    assert_template 'community_markers/form'
    assert_kind_of CommunityMarker, assigns(:community_marker)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    attributes = valid_community_marker_plan

    assert_no_difference(['CommunityMarker.count']) do
      post :confirm_before_create, :community_marker => attributes,
           :community_id => attributes[:community_id]
    end

    assert_response :success
    assert_template 'community_markers/confirm'
    assert_equal true, assigns(:community_marker).valid?

    community_marker = assigns(:community_marker)

    attributes.each do |key, value|
      assert_equal value, community_marker.send(key)
    end
  end

  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    community = set_community_and_has_role

    attributes = {
      :title => "", :content => "test_title",
      :latitude => 11.111111, :longitude => 111.111111
    }

    assert_no_difference(['CommunityMarker.count']) do
      post :confirm_before_create, :community_marker => attributes,
           :community_id => community.id
    end

    assert_response :success
    assert_template 'community_markers/form'
    assert_equal false, assigns(:community_marker).valid?
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    community = set_community_and_has_role

    post :confirm_before_create, :community_marker => {}, :clear => "Clear",
         :community_id => community.id

    assert_response :redirect
    assert_redirected_to new_community_marker_path
  end

  # 登録データの作成
  def test_create_community_marker
    attributes = valid_community_marker_plan

    assert_difference(['CommunityMarker.count']) do
      post :create, :community_marker => attributes,
           :community_id => attributes[:community_id]
    end

    community_marker = assigns(:community_marker)

    attributes.each do |key, value|
      assert_equal value, community_marker.send(key)
    end

    assert_redirected_to complete_after_create_community_marker_path(:id => community_marker, :community_id => community_marker.community)
  end

  # 登録データの作成キャンセル
  def test_create_community_marker_cancel
    community = set_community_and_has_role

    assert_no_difference(['CommunityMarker.count']) do
      post :create, :community_marker => CommunityMarker.plan, :cancel => "Cancel",
           :community_id => community.id
    end

    assert_not_nil assigns(:community_marker)
    assert_template 'community_markers/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_community_marker_fail
    community = set_community_and_has_role
    community_map = CommunityMapCategory.make(:community => community)
    attributes = {:title => "test"}

    assert_no_difference(['CommunityMarker.count']) do
      post :create, :community_marker => attributes,
           :community_id => community.id
    end

    assert_template 'community_markers/form'
  end

  # 詳細画面の表示
  def test_show_community_marker
    community_marker = CommunityMarker.make

    get :show, :id => community_marker.id,
        :community_id => community_marker.community.id

    assert_response :success
    assert_template 'community_markers/show'
    assert_kind_of CommunityMarker, assigns(:community_marker)
  end

  # 編集画面の表示
  def test_edit
    marker = set_community_marker

    get :edit, :id => marker.id, :community_id => marker.community_id

    assert_response :success
    assert_template 'community_markers/form'
    assert_kind_of CommunityMarker, assigns(:community_marker)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    marker = set_community_marker

    post(:confirm_before_update, :id => marker.id,
         :community_marker => marker.attributes,
         :community_id => marker.community_id)

    assert_response :success
    assert_template 'community_markers/confirm'
    assert_equal true, assigns(:community_marker).valid?
  end

  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    marker = set_community_marker

    post(:confirm_before_update, :id => marker.id,
         :community_marker => {:title => ""},
         :community_id => marker.community_id)

    assert_response :success
    assert_template 'community_markers/form'
    assert_equal false, assigns(:community_marker).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    marker = set_community_marker

    post(:confirm_before_update, :id => marker.id,
         :community_marker => marker.attributes,
         :community_id => marker.community_id, :clear => 'Clear')

    assert_response :redirect
    assert_redirected_to edit_community_marker_path(:id => marker.id, :community_id => marker.community_id)
  end

  # 編集データの更新
  def test_update_community_marker
    marker = set_community_marker

    update_attributes = {
      :title => "new title",
      :content => "new content"
    }

    assert_no_difference(['CommunityMarker.count']) do
    put(:update, :id => marker.id,
        :community_marker => update_attributes,
        :community_id => marker.community_id)
    end

    updated_marker = assigns(:community_marker)

    update_attributes.each do |key, value|
      assert_equal value, updated_marker.send(key)
    end

    assert_redirected_to complete_after_update_community_marker_path(:id => updated_marker.id, :community_id => updated_marker.community_id)
  end

  # 編集データの作成キャンセル
  def test_update_community_marker_cancel
    marker = set_community_marker

    put(:update, :id => marker.id, :cancel => 'Cancel',
        :community_marker => marker.attributes,
        :community_id => marker.community_id)

    assert_not_nil assigns(:community_marker)
    assert_template 'community_markers/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_community_marker_fail
    marker = set_community_marker

    invalid_attributes = {:title => "" }

    put(:update, :id => marker.id,
        :community_marker => invalid_attributes,
        :community_id => marker.community_id)

    marker.reload

    invalid_attributes.each do |key, value|
      assert_not_equal value, marker.send(key)
    end

    assert_template 'community_markers/form'
  end

  # レコードの削除
  def test_destroy_community_marker
    marker = set_community_marker

    assert_difference('CommunityMarker.count', -1) do
      delete :destroy, :id => marker.id, :community_id => marker.community_id
    end

    assert_redirected_to search_community_threads_path(:community_id => marker.community_id)
  end

  # 匿名ユーザへのaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_anonymous_by_visibility
    logout
    community = Community.make
    marker = CommunityMarker.make(:community => community)

    get :show, :id => marker.id, :community_id => community.id

    assert_response :success
    assert_template "community_markers/show"

    [:member, :approval_required_and_private, :secret].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      assert_raise Acl9::AccessDenied do
        get :show, :id => marker.id, :community_id => community.id
      end
    end
  end

  # ログインユーザへのaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_logged_in_user_by_visibility
    community = Community.make
    marker = CommunityMarker.make(:community => community)

    [:public, :member].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      get :show, :id => marker.id, :community_id => community.id
      assert_response :success
      assert_template "community_markers/show"
    end

    [:approval_required_and_private, :secret].each do |v|
      community.update_attributes!(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[v])
      assert_raise Acl9::AccessDenied do
        get :show, :id => marker.id, :community_id => community.id
      end
    end
  end

  #  コミュニティメンバーへのwaccess_controlテスト
  # この制限は全てのアクションに適用されるので、showアクションのみでテストを行う
  def test_access_control_member_by_visibility
    community = set_community_and_has_role("community_general")
    marker = CommunityMarker.make(:community => community)

    Community::APPROVALS_AND_VISIBILITIES.each_value do |v|
      community.update_attributes!(:participation_and_visibility => v)
      get :show, :id => marker.id, :community_id => community.id
      assert_response :success
      assert_template "community_markers/show"
    end
  end

  # メンバーでないユーザが、マーカーを作成しようとするとトップページへ飛ばされる動作のテスト
  def test_verify_marker_createable_without_login
    community = Community.make(:topic_createable_admin_only => false)

    get :new, :community_id => community.id

    assert_redirected_to root_path

    community.update_attributes(:topic_createable_admin_only => true)

    get :new, :community_id => community.id

    assert_redirected_to root_path
  end

  # メンバーがマーカーを作成しようとするとき、権限が無ければトップページへ飛ばされる動作のテスト
  def test_verify_marker_createable_for_member
    community = set_community_and_has_role("community_general",
                                           :topic_createable_admin_only => false)

    get :new, :community_id => community.id

    assert_response :success
    assert_template "form"

    community.update_attributes!(:topic_createable_admin_only => true)

    get :new, :community_id => community.id

    assert_redirected_to root_path
  end

  # 副管理人は、制限によらず常にマーカーを作成できることをテスト
  def test_verify_marker_createable_for_sub_admin
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

  # 管理人は、制限によらず常にマーカーを作成できることをテスト
  def test_verify_marker_createable_for_sub_admin
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
  def test_verify_marker_editable_or_destroyable
    community = set_community_and_has_role("community_general")
    marker = CommunityMarker.make(:community => community)

    get :edit, :id => marker.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to root_path
    delete :destroy, :id => marker.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to root_path

    marker = CommunityMarker.make(:community => community, :author => @current_user)
    get :edit, :id => marker.id, :community_id => community.id
    assert_response :success
    assert_template "community_markers/form"
    delete :destroy, :id => marker.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to  search_community_threads_path(:community_id => community.id)

    @current_user.has_no_roles_for!(community)
    @current_user.has_role!("community_sub_admin", community)
    marker = CommunityMarker.make(:community => community)
    get :edit, :id => marker.id, :community_id => community.id
    assert_response :success
    assert_template "community_markers/form"
    delete :destroy, :id => marker.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to  search_community_threads_path(:community_id => community.id)

    @current_user.has_no_roles_for!(community)
    @current_user.has_role!("community_admin", community)
    marker = CommunityMarker.make(:community => community)
    get :edit, :id => marker.id, :community_id => community.id
    assert_response :success
    assert_template "community_markers/form"
    delete :destroy, :id => marker.id, :community_id => community.id
    assert_response :redirect
    assert_redirected_to  search_community_threads_path(:community_id => community.id)
  end

  # コミュニティマップ表示（RSS2）
  def test_map_rss2
    community = Community.make
    marker = community.markers.make

    get :map, :format => "rss", :community_id => community.id

    assert_template('communities/feed.rxml')
    assert_not_nil assigns(:xml_title)
    assert_not_nil assigns(:xml_link)
  end

  # コミュニティマップ表示（RSS1.0）
  def test_map_rdf
    community = Community.make
    marker = community.markers.make

    get :map, :format => "rdf", :community_id => community.id

    assert_template('communities/feed.rdf.builder')
  end

  # コミュニティマップ表示（Atom）
  def test_map_atom
    community = Community.make
    marker = community.markers.make

    get :map, :format => "atom", :community_id => community.id

    assert_template('communities/feed.atom.builder')
  end

  private

  def valid_community_marker_plan(attrs = {})
    community = set_community_and_has_role
    map_category =
      CommunityMapCategory.make(:community => community,
                                :author => @current_user)

    plan = CommunityMarker.plan(:community => community,
                                :author => @current_user,
                                :map_category => map_category).merge(attrs)
  end

  def set_community_marker(attrs = {})
    community = Community.make

    CommunityMarker.make({:community => community,
                         :author => @current_user}.merge(attrs))
  end
end

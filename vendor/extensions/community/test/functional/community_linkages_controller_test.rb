require File.dirname(__FILE__) + '/../test_helper'

# コミュニティリンク管理テスト
class CommunityLinkagesControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    @community = set_community_and_has_role
    login_as(@current_user)
  end

  # 一覧画面の表示
  def test_index
    get :index, :community_id => @community.id

    assert_response :success
    assert_template 'community_linkages/index'
    assert_not_nil assigns(:community_linkages)
  end

  # コミュニティ管理者用一覧画面の表示
  def test_index_for_admin
    get  :index_for_admin, :community_id => @community.id

    assert_response :success
    assert_template 'community_linkages/index_for_admin'
    assert_not_nil assigns(:community_linkages)
  end

  # 登録画面(内部リンク用)の表示
  def test_new_for_inner_linkage
    get :new, :kind => "CommunityInnerLinkage", :community_id => @community.id

    assert_response :success
    assert_template 'community_linkages/form'
    assert_kind_of CommunityInnerLinkage, assigns(:community_linkage)
  end

  # 登録画面(外部リンク用)の表示
  def test_new_for_outer_linkage
    get :new, :kind => "CommunityOuterLinkage", :community_id => @community.id

    assert_response :success
    assert_template 'community_linkages/form'
    assert_kind_of CommunityOuterLinkage, assigns(:community_linkage)
  end

  # 登録データ確認画面(内部リンク用)表示
  def test_confirm_before_create_for_inner_linkage
    assert_no_difference(['CommunityLinkage.count']) do
      post :confirm_before_create, :community_inner_linkage => {:kind => "CommunityInnerLinkage", :link_id => Community.make.id}, :community_id => @community.id
    end

    assert_response :success
    assert_template 'community_linkages/confirm'
    assert_equal true, assigns(:community_linkage).valid?
  end

  # 登録データ確認画面(外部リンク用)表示
  # NOTE: 実際は外部SSLを取得しに行くが、テストでそれはしたくないので、そのあたりの挙動を変えている
  def test_confirm_before_create_for_outer_linkage
    change_parse_behavior do
      assert_no_difference(['CommunityLinkage.count']) do
        post :confirm_before_create, :community_outer_linkage => {:kind => "CommunityOuterLinkage", :rss_url => "test"}, :community_id => @community.id
      end

      assert_response :success
      assert_template 'community_linkages/confirm'
      assert_equal true, assigns(:community_linkage).valid?
    end
  end

  # 登録データ確認画面表示失敗(内部リンク)
  def test_confirm_before_create_fail_for_inner_linkage
    assert_no_difference(['CommunityLinkage.count']) do
      post :confirm_before_create, :community_inner_linkage => {:kind => "CommunityInnerLinkage", :link_id => ""}, :community_id => @community.id
    end

    assert_response :success
    assert_template 'community_linkages/form'
    assert_equal false, assigns(:community_linkage).valid?
  end

  # 登録データ確認画面表示失敗(外部リンク)
  def test_confirm_before_create_fail_for_outer_linkage
    assert_no_difference(['CommunityLinkage.count']) do
      post :confirm_before_create, :community_outer_linkage => {:kind => "CommunityOuterLinkage", :rss_url => ""}, :community_id => @community.id
    end

    assert_response :success
    assert_template 'community_linkages/form'
    assert_equal false, assigns(:community_linkage).valid?
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    post :confirm_before_create, :community_inner_linkage => {}, :clear => "Clear", :community_id => @community.id

    assert_response :redirect
    assert_redirected_to new_community_linkage_path
  end

  # 登録データの作成(内部リンク)
  def test_create_community_inner_linkage
    inner_link_id = Community.make.id

    assert_difference(['CommunityLinkage.count']) do
      post :create, :community_inner_linkage => {:kind => "CommunityInnerLinkage", :link_id => inner_link_id}, :community_id => @community.id
    end

    community_linkage = assigns(:community_linkage)
    assert_equal community_linkage.inner_link.id, inner_link_id
    assert_kind_of CommunityInnerLinkage, community_linkage

    assert_redirected_to complete_after_create_community_linkage_path(:id => community_linkage.id, :community_id => @community.id)
  end

  # 登録データの作成(外部リンク)
  def test_create_community_outer_linkage
    change_parse_behavior do
      community = set_community_and_has_role
      outer_link_id = Community.make.id

      assert_difference(['CommunityLinkage.count']) do
        post :create, :community_outer_linkage => {:kind => "CommunityOuterLinkage", :rss_url => "test"}, :community_id => community.id
      end

      community_linkage = assigns(:community_linkage)
      assert_equal community_linkage.rss_url, "test"
      assert_kind_of CommunityOuterLinkage, community_linkage

      assert_redirected_to complete_after_create_community_linkage_path(:id => community_linkage.id, :community_id => community.id)
    end
  end

  # 登録データの作成キャンセル
  def test_create_community_linkage_cancel
    assert_no_difference(['CommunityLinkage.count']) do
      post :create, :community_inner_linkage => {:kind => "CommunityInnerLinkage"}, :community_id => @community.id,  :cancel => "Cancel"
    end

    assert_not_nil assigns(:community_linkage)
    assert_template 'community_linkages/form'
  end

  # 登録データ作成の失敗（バリデーション）（内部リンク）
  def test_create_community_inner_linkage_fail
    assert_no_difference(['CommunityLinkage.count']) do
      post :create, :community_inner_linkage => {:kind => "CommunityInnerLinkage", :link_id => ""}, :community_id => @community.id
    end

    assert_template 'community_linkages/form'
  end

  # 登録データ作成の失敗（バリデーション）（外部リンク）
  def test_create_community_outer_linkage_fail
    assert_no_difference(['CommunityLinkage.count']) do
      post :create, :community_outer_linkage => {:kind => "CommunityOuterLinkage", :rss_url => ""}, :community_id => @community.id
    end

    assert_template 'community_linkages/form'
  end

  # レコードの一括削除
  def test_destroy_checked_ids
    ids = Array.new(2) do
      CommunityInnerLinkage.make(:owner => @community, :inner_link => Community.make).id
    end

    target_id = CommunityInnerLinkage.make.id
    assert_difference('CommunityInnerLinkage.count', -2) do
      delete :destroy_checked_ids, :community_linkage_ids => ids, :community_id => @community.id
    end

    assert_redirected_to index_for_admin_community_linkages_path(:community_id => @community.id)
  end

  # レコードの一括削除の失敗
  def test_destroy_community_linkage_fail
    ids = [CommunityInnerLinkage.make(:owner => Community.make, :inner_link => Community.make).id]

    target_id = CommunityInnerLinkage.make.id
    assert_no_difference('CommunityInnerLinkage.count') do
      delete :destroy_checked_ids, :community_linkage_ids => ids, :community_id => @community.id
    end

    assert_redirected_to index_for_admin_community_linkages_path(:community_id => @community.id)
  end

  # indexへのアクセス制限テスト
  # 非ログインユーザのとき
  def test_access_to_index_anonymous
    logout

    # コミュニティが非公開、ログインメンバーに公開のときはアクセスできない
    [:approval_required_and_private, :member].each do |visibility|
      community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[visibility])
      assert_raise Acl9::AccessDenied do
        get :index, :community_id => community.id
      end
    end

    # コミュニティが外部公開のときはアクセスできる
    community = Community.make
    get :index, :community_id => community.id
    assert_response :success
  end

  # indexへのアクセス制限テスト
  # ログインユーザであるが、コミュニティのメンバーではないとき
  def test_access_to_index_login_user_but_not_community_member
    # コミュニティが非公開のときはアクセスできない
    community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_private])

    assert_raise Acl9::AccessDenied do
      get :index, :community_id => community.id
    end

    # コミュニティ全体公開、及び外部公開のときはアクセスできる
    [:public, :member].each do |visibility|
      community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[visibility])
      get :index, :community_id => community.id
      assert_response :success
    end
  end

  # indexへのアクセス制限テスト
  # コミュニティのメンバーのとき
  def test_access_to_index_login_user
    # コミュニティが外部公開、全体公開、及び外部公開のときアクセスできる
    [:public, :member].each do |visibility|
      community = set_community_and_has_role("community_general",
                                             :visibility => Community::VISIBILITIES[visibility])
      get :index, :community_id => community.id
      assert_response :success
    end
  end

  # index_for_adminへのアクセス制限テスト
  # ログインしていないとき
  def test_access_to_index_for_admin_anonymous
    logout
    assert_raise Acl9::AccessDenied do
      get :index_for_admin, :community_id => Community.make.id
    end
  end

  # index_for_adminへのアクセス制限テスト
  # ログインしているが、コミュニティのメンバーではないとき
  def test_access_to_index_for_admin_login_user
    assert_raise Acl9::AccessDenied do
      get :index_for_admin, :community_id => Community.make.id
    end
  end

  # index_for_adminへのアクセス制限テスト
  # コミュニティのメンバーのとき
  def test_access_to_index_for_admin_community_member
    # 一般権限だと入れない
    assert_raise Acl9::AccessDenied do
      get :index_for_admin, :community_id => set_community_and_has_role("community_general")
    end

    # 副管理人、及び管理人であれば見れる
    ["community_admin", "community_sub_admin"].each do |role|
      get :index_for_admin, :community_id => set_community_and_has_role(role)
      assert_response :success
    end
  end

  private

  def change_parse_behavior(&block)
    CommunityOuterLinkage.module_eval do
      def parse_file
        @rss = RSS::Parser.parse(RAILS_ROOT + '/test/fixtures/files/test.rss', false)
        return true
      end

      alias :parse_orig :parse
      alias :parse  :parse_file

      block.call

      alias :parse :parse_orig
    end
  end
end

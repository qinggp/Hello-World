require File.dirname(__FILE__) + '/../test_helper'

# コミュニティ機能テスト
CommunitiesController.class_eval { def rescue_action(e) raise e end }

class CommunitiesControllerTest < ActionController::TestCase

  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # 自分の参加しているコミュニティ一覧画面（ログイン状態）
  def test_index
    set_communities_and_take_part_in(1)

    get :index

    assert_response :success
    assert_equal @current_user.id, assigns(:user).id
    assert_equal 1, assigns(:communities).size
  end

  # 自分の管理しているコミュニティ一覧画面（ログイン状態）
  def test_index_admin_community
    set_community_and_has_role("community_general")
    admin_community = set_community_and_has_role

    get :index, :role => "admin"

    assert_response :success
    assert_equal @current_user.id, assigns(:user).id
    assert_equal 1, assigns(:communities).size
    assert_equal admin_community.id, assigns(:communities).first.id
  end

  # 新着コミュニティトピック表示（RSS2）
  def test_index_rss2
    get :index_feed, :format => "rss"

    assert_template('feed.rxml')
    assert_not_nil assigns(:xml_title)
    assert_not_nil assigns(:xml_link)
  end

  # 新着コミュニティトピック表示（RSS1.0）
  def test_index_rdf
    get :index_feed, :format => "rdf"

    assert_template('feed.rdf.builder')
  end

  # 新着コミュニティトピック表示（Atom）
  def test_index_atom
    get :index_feed, :format => "atom"

    assert_template('feed.atom.builder')
  end

  # 新着コミュニティトピック表示（RSS2）
  def test_index_feed_for_community_rss2
    community = Community.make
    topic = community.topics.make
    marker = community.markers.make
    event = community.events.make
    comment = event.replies.make(:community => community, :author => @current_user)

    get :index_feed_for, :format => "rss", :id => community.id

    assert_template('feed.rxml')
    assert_not_nil assigns(:xml_title)
    assert_not_nil assigns(:xml_link)
  end

  # 新着コミュニティトピック表示（RSS1.0）
  def test_index_feed_for_community_rdf
    community = Community.make
    topic = community.topics.make
    marker = community.markers.make
    event = community.events.make
    comment = event.replies.make(:community => community, :author => @current_user)

    get :index_feed_for, :format => "rdf", :id => community.id

    assert_template('feed.rdf.builder')
  end

  # 新着コミュニティトピック表示（Atom）
  def test_index_feed_for_community_atom
    community = Community.make
    topic = community.topics.make
    marker = community.markers.make
    event = community.events.make
    comment = event.replies.make(:community => community, :author => @current_user)

    get :index_feed_for, :format => "atom", :id => community.id

    assert_template('feed.atom.builder')
  end

  # コミュニティ一覧画面で表示件数を指定したときのページネーションの結果が正しいことを確認する
  def test_index_received_per_page
    set_communities_and_take_part_in

    get :index, :per_page => 10

    expected_total_pages = (@current_user.communities.count / 10.0).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:communities).total_pages
    assert_equal 1, assigns(:communities).current_page
    assert_equal 10, assigns(:communities).size
  end

  # コミュニティ一覧画面でページ数を指定したときのページネーションの結果が正しいことを確認する
  def test_index_received_per_page
    set_communities_and_take_part_in

    get :index, :page => 2

    default_per_page = 30
    expected_total_pages = (@current_user.communities.count / default_per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:communities).total_pages
    assert_equal 2, assigns(:communities).current_page
    assert_equal default_per_page, assigns(:communities).size
  end

  # コミュニティ一覧画面で表示件数とページ数を指定したときの
  # ページネーションの結果が正しいことを確認する
  def test_index_received_per_page
    set_communities_and_take_part_in

    page = 2
    per_page = 10

    get :index, :page => page, :per_page => per_page

    expected_total_pages = (@current_user.communities.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:communities).total_pages
    assert_equal page, assigns(:communities).current_page
    assert_equal per_page, assigns(:communities).size
  end

  # コミュニティ検索画面（ログイン状態）
  def test_search
    get :search

    assert_response :success
  end

  # コミュニティ検索画面（非ログイン状態）
  def test_search_without_logged_in
    Community.destroy_all

    Community::APPROVALS_AND_VISIBILITIES.each_value do |participation_and_visibility|
      Community.make(:participation_and_visibility => participation_and_visibility)
    end

    logout

    get :search

    communities = assigns(:communities)
    assert_equal 2, communities.count
    communities.each { |c| assert c.visibility_public? }

    assert_response :success
  end

  # コミュニティ新規作成画面
  def test_new
    get :new

    assert_response :success
  end

  # コミュニティ設定変更画面
  def test_edit
    community = set_community_and_has_role

    get :edit, :id => community.id

    assert_response :success
  end

  # コミュニティ新規作成確認画面
  def test_confirm_before_create
    community_category = community_categories(:music)

    attributes =
      Community.plan(:community_category_id => community_category.id,
                     :latitude => 42.123456,
                     :longitude => 123.45678,
                     :zoom => 7)

    assert_no_difference "Community.count" do
      post :confirm_before_create,
           :community => attributes.merge(:image => upload("#{RAILS_ROOT}/public/images/rails.png"))
    end

    assert_response :success
    assert_template :"confirm"

    attributes.each do |attribute, value|
      assert_equal value, assigns(:community).send(attribute)
    end

    assert File.exists?(assigns(:community).image)
  end

  # コミュニティ設定変更確認画面
  def test_confirm_before_update
    community =
      set_community_and_has_role(:community_category => community_categories(:music))

    updating_attributes = {:comment => "テストコミュニティ", :latitude => 42.123456,
                           :longitude => 123.45678, :zoom => 7}

    current_attributes = community.attributes

    assert_no_difference "Community.count" do
      post :confirm_before_update, :id => community.id,
           :community => updating_attributes.merge(:image => upload("#{RAILS_ROOT}/public/images/rails.png"))
    end

    assert_response :success
    assert_template :"confirm"

    updating_attributes.each do |attribute, value|
      assert_equal value, assigns(:community).send(attribute)
    end

    assert File.exists?(assigns(:community).image)
  end

  # コミュニティ作成後、コミュニティ作成完了画面
  def test_create
    attributes = Community.plan(:latitude => 42.123456,
                                :longitude => 123.45678,
                                :zoom => 7)

   assert_difference "Community.count" do
      post :create, :community => attributes
    end

    community = assigns(:community)
    assert_response :redirect
    assert_redirected_to complete_after_create_community_path(:id => community.id)
    assert "作成完了いたしました", assigns(:message)

    attributes.each do |attribute, value|
      assert_equal value, community.send(attribute)
    end

    assert community.member?(@current_user)
    assert @current_user.has_role?(:community_admin, community)
  end

  # コミュニティ作成後、公認コミュニティ（管理人）に参加していることをテスト
  def test_become_official_community_admin_only_member_after_create
    official_community_admin_only = Community.make(:official => Community::OFFICIALS[:admin_only])

    attributes = Community.plan(:latitude => 42.123456,
                                :longitude => 123.45678,
                                :zoom => 7)

    post :create, :community => attributes

    community = assigns(:community)
    assert_response :redirect
    assert_redirected_to complete_after_create_community_path(:id => community.id)
    assert "作成完了いたしました", assigns(:message)

    assert community.member?(@current_user)
    assert @current_user.has_role?(:community_admin, community)

    assert official_community_admin_only.member?(@current_user)
    assert @current_user.has_role?(:community_general, official_community_admin_only)
  end

  # コミュニティ設定変更後、コミュニティ設定変更完了画面
  def test_update
    community =
      set_community_and_has_role(:community_category =>
                                 community_categories(:music))

    current_attributes = Community.plan
    updating_attributes =
      Community.plan(:comment => "テストコミュニティ",
                     :latitude => 42.123456,
                     :longitude => 123.45678,
                     :zoom => 7)

   assert_no_difference "Community.count" do
      post :update, :id => community.id, :community => updating_attributes
    end

    community.reload
    assert_response :redirect
    assert_redirected_to complete_after_update_community_path(community.id)
    assert "修正完了いたしました", assigns(:message)

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, community.send(attribute)
    end
  end

  # コミュニティ詳細画面
  def test_show
    community = set_community_and_has_role(:community_category => community_categories(:music))

    get :show, :id => community.id

    assert_response :success
  end

  # コミュニティ削除確認画面
  def test_confirm_before_destroy
    community = set_community_and_has_role(:community_category => community_categories(:music))

    post :confirm_before_destroy, :id => community.id

    assert_response :success
  end

  # コミュニティ削除後、完了画面の表示
  def test_destroy
    community = set_community_and_has_role
    id = community.id

    assert_difference "Community.count", -1 do
      delete :destroy, :id => id
    end

    assert_response :redirect
    assert_redirected_to complete_after_destroy_new_community_path
    assert !Community.exists?(id)
    assert "削除完了いたしました", assigns(:message)
  end

  # コミュニティ削除後、その管理人が他に管理人をしておらず、公認コミュニティ（管理人）のメンバーであれば、除外される
  def test_remove_member_from_official_admin_only_when_destroy
    official_community_admin_only = Community.make(:official => Community::OFFICIALS[:admin_only])
    Community.add_member_to_official_admin_only(@current_user)
    assert official_community_admin_only.member?(@current_user)

    community = set_community_and_has_role

    delete :destroy, :id => community.id

    assert !official_community_admin_only.member?(@current_user)
    assert_response :redirect
    assert_redirected_to complete_after_destroy_new_community_path
  end

  # パラメータを何も指定しないときのコミュニティ検索結果の件数が全件と一致する
  def test_search_received_no_paramaters
    get :search

    assert_response :success
    assert Community.count, assigns(:communities).total_entries
  end

  # keywordを指定したときのコミュニティの検索結果が正しいことを確認する
  def test_search_received_keyword
    set_communities_for_search

    get :search, :keyword => "松江"

    assert_response :success
    assert_equal 1, assigns(:communities).total_entries
    assert_equal "松江のイベント情報", assigns(:communities).first.name
  end

  # カテゴリを指定したときのコミュニティの検索結果が正しいことを確認する
  def test_search_received_category
    set_communities_for_search

    get :search, :community_category_id => 21

    assert_response :success
    assert_equal 2, assigns(:communities).total_entries
    ["ラーメン", "カレー"].each_with_index do |name, index|
      assert_equal name, assigns(:communities)[index].name
    end
  end

  # keywordとカテゴリを同時に指定したときの検索結果が正しいことを確認する
  def test_search_received_keyword_and_category
    set_communities_for_search

    get :search, :keyword => "カレー", :community_category_id => 21

    assert_response :success
    assert_equal 1, assigns(:communities).total_entries
    assert_equal "カレー", assigns(:communities).first.name
  end

  # 1ページ当りの件数を指定したときのページネーションの結果が正しいことを確認する
  def test_search_received_per_page
    set_communities_for_pagination

    get :search, :per_page => 10

    expected_total_pages = (Community.count / 10.0).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:communities).total_pages
  end

  # 表示するページ番号を指定したときのページネーションの結果が正しいことを確認する
  def test_search_received_page
    set_communities_for_pagination

    get :search, :page => 3

    assert_response :success
    assert_equal 3, assigns(:communities).current_page
  end

  # 1ページ当りの件数と、表示するページ番号を同時に指定したときのページネーションの結果が
  # 正しいことを確認する
  def test_search_received_page_and_per_page
    set_communities_for_pagination

    get :search, :per_page => 2, :page => 10

    expected_total_pages = (Community.count / 2.0).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:communities).total_pages
    assert_equal 10, assigns(:communities).current_page
  end

  # 公認コミュニティが存在するときの公認コミュニティの数が一致するか確認する
  def test_search_when_existence_official
    set_official_communities

    get :search

    assert_response :success
    assert_equal 3, assigns(:official_communities).count
  end

  # 公認コミュニティを検索したときの結果を確認する
  def test_search_official
    set_official_communities

    get :search, :type => "official"

    assert_response :success
    assert_equal 3, assigns(:communities).count
  end

  # 承認なしのときのコミュニティ参加申請
  def test_apply_without_aprooval
    community = Community.make(:approval_required => false)

    assert !community.member?(@current_user)

    assert_difference "CommunityMembership.count" do
      post :apply, :id => community.id
    end

    assert_response :redirect
    assert_redirected_to community_path(community)

    assert community.member?(@current_user)
    assert @current_user.has_role?(:community_general, community)
  end

  # 承認ありのときのコミュニティ参加申請
  def test_apply_required_approval
    community = Community.make(:participation_and_visibility =>
                               Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_member])
    message = "お願いします"

    assert !community.member?(@current_user)

    assert_no_difference "CommunityMembership.count" do
      assert_difference "PendingCommunityUser.count" do
        post :apply, :id => community.id, :message => message
      end
    end

    pending =
      PendingCommunityUser.by_pending_user(@current_user).by_community(community).first

    assert_response :redirect
    assert_redirected_to community_path(community)
    assert community.pending?(@current_user)
    assert_equal message, pending.apply_message
  end

  # 承認ありで、既に招待を受けている場合は承認無しで参加
  def test_apply_required_approval_after_invited
    community = Community.make(:participation_and_visibility =>
                               Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_member])

    PendingCommunityUser.create(:state => "invited", :user => @current_user, :community => community)

    assert_difference "CommunityMembership.count" do
      assert_no_difference "PendingCommunityUser.count" do
        post :apply, :id => community.id
      end
    end

    community.reload
    assert_response :redirect
    assert_redirected_to community_path(community)
    assert community.member?(@current_user)
  end

  # コミュニティ参加申請を許可
  def test_approve
    community = set_community_and_has_role(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_member])
    pending =
      PendingCommunityUser.make(:community => community,
                                :user_id => User.make.id)

    message = "OK"

    assert_difference "CommunityMembership.count" do
      post :approve_or_reject, :approve => true, :pending_id => pending.id,
           :id => community.id, :message => message
    end

    assert_response :redirect
    assert_redirected_to community_path(community)

    pending.reload
    assert pending.active?
    assert_nil pending.reject_message
    assert @current_user.has_role?("community_admin", community)
  end

  # コミュニティ参加申請を却下
  def test_reject
    community =
      set_community_and_has_role(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_member])

    pending =
      PendingCommunityUser.make(:user_id => User.make.id,
                                :community => community)
    message = "ダメ"

    assert_no_difference "CommunityMembership.count" do
      post :approve_or_reject, :reject => true, :pending_id => pending.id,
           :id => community.id, :message => message
    end

    assert_response :redirect
    assert_redirected_to community_path(community)

    pending.reload
    assert pending.rejected?
    assert_equal message, pending.reject_message
    assert !@current_user.has_role?(:community_general, community)
  end

  # 一般権限時のコミュニティ退会
  def test_cancel_with_general_authority
    community = set_community_and_has_role("community_general")

    assert community.member?(@current_user)

    assert_difference "CommunityMembership.count", -1 do
      post :cancel, :id => community.id
    end

    assert_response :redirect
    assert_redirected_to community_path(community)

    assert !community.member?(@current_user)
    assert !@current_user.has_roles_for?(@community)
  end

  # 副管理人のときのコミュニティ退会
  def test_cancel_with_sub_admin_authority
    community = set_community_and_has_role("community_sub_admin")

    assert community.member?(@current_user)

    assert_difference "CommunityMembership.count", -1 do
      post :cancel, :id => community.id
    end

    assert_response :redirect
    assert_redirected_to community_path(community)

    assert !community.member?(@current_user)
    assert !@current_user.has_roles_for?(@community)
  end

  # 自分の参加しているコミュニティ画面へのアクセスチェック
  def test_index_without_login
    logout

    assert_raise Acl9::AccessDenied do
      get :index
    end
  end

  # ログインしていない状態でコミュニティ作成関連のアクセスチェック
  def test_related_creation_without_login
    logout

    assert_raise Acl9::AccessDenied do
      get :new
    end

    assert_raise Acl9::AccessDenied do
      post :confirm_before_create
    end

    assert_raise Acl9::AccessDenied do
      post :create
    end
  end

  # ログインしていない状態でコミュニティ設定変更関連のアクセスチェック
  def test_related_update_without_login
    logout

    community = Community.make

    assert_raise Acl9::AccessDenied do
      get :edit, :id => community.id
    end

    assert_raise Acl9::AccessDenied do
      post :confirm_before_update, :id => community.id
    end

    assert_raise Acl9::AccessDenied do
      post :update, :id => community.id
    end
  end

  # コミュニティ設定変更関連の権限が無いときのアクセスチェック
  def test_related_update_with_no_authority
    roles = ["community_general", "community_sub_admin"]
    roles.each do |role|
      community = set_community_and_has_role(role)

      assert_raise Acl9::AccessDenied do
        get :edit, :id => community.id
      end

      assert_raise Acl9::AccessDenied do
        post :confirm_before_update, :id => community.id
      end

      assert_raise Acl9::AccessDenied do
        post :update, :id => community.id
      end
    end
  end

  # コミュニティ削除関連の権限が無いときのアクセスチェック
  def test_related_destroy_with_no_authority
    roles = ["community_general", "community_sub_admin"]
    roles.each do |role|
      community = set_community_and_has_role(role)

      assert_raise Acl9::AccessDenied do
        get :confirm_before_destroy, :id => community.id
      end

      assert_raise Acl9::AccessDenied do
        post :destroy, :id => community.id
      end
    end
  end

  # ログインしていない状態で、コミュニティ参加申請関連のアクセスチェック
  def test_related_apply_without_login
    logout

    community = Community.make

    assert_raise Acl9::AccessDenied do
      get :confirm_before_apply, :id => community.id
    end

    assert_raise Acl9::AccessDenied do
      post :apply, :id => community.id
    end
  end

  # ログインしていて、既にそのコミュニティに参加している（権限がある）
  # 状態で参加申請関連のアクセスチェック
  def test_related_apply_when_already_participating
    roles = ["community_general", "community_sub_admin", "community_admin"]
    roles.each do |role|
      community = set_community_and_has_role(role)

      assert_raise Acl9::AccessDenied do
        get :confirm_before_apply, :id => community.id
      end

      assert_raise Acl9::AccessDenied do
        post :apply, :id => community.id
      end
    end
  end

  # ログインしていない状態でコミュニティ退会関連のアクセスチェック
  def test_related_cancel_without_login
    logout

    community = Community.make

    assert_raise Acl9::AccessDenied do
      get :confirm_before_cancel, :id => community.id
    end

    assert_raise Acl9::AccessDenied do
      post :cancel, :id => community.id
    end
  end

  # 管理者権限のとき、退会関連のアクセスチェック
  def test_related_cancel_with_admin_authority
    community = set_community_and_has_role

    assert_raise Acl9::AccessDenied do
      get :confirm_before_cancel, :id => community.id
    end

    assert_raise Acl9::AccessDenied do
      post :cancel, :id => community.id
    end
  end

  # ログインしていない状態で、コミュニティ参加要請承認・却下関連のアクセスチェック
  def test_related_approve_or_reject_without_login
    logout

    community = Community.make

    assert_raise Acl9::AccessDenied do
      get :show_application, :id => community.id
    end

    assert_raise Acl9::AccessDenied do
      post :approve_or_reject, :id => community.id
    end
  end

  # 一般権限で、コミュニティ参加要請承認・却下関連のアクセスチェック
  def test_related_approve_or_reject_with_general_authority
    community = set_community_and_has_role("admin_general")

    assert_raise Acl9::AccessDenied do
      get :show_application, :id => community.id
    end

    assert_raise Acl9::AccessDenied do
      post :approve_or_reject, :id => community.id
    end
  end

  # コミュニティの公開設定がSNSメンバーのみ公開になっている場合のアクセスチェック
  def test_show_with_visibility_member
    logout

    community = Community.make(:visibility => 2)

    assert_raise Acl9::AccessDenied do
      get :show_application, :id => community.id
    end
  end

  # コミュニティの公開設定が、コミュニティの参加メンバーのみになっている場合のアクセスチェック
  def test_show_with_visibility_private
    community = Community.make(:visibility => 1)

    assert_raise Acl9::AccessDenied do
      get :show_application, :id => community.id
    end

    logout

    assert_raise Acl9::AccessDenied do
      get :show_application, :id => community.id
    end
  end

  # コミュニティ作成完了画面
  def test_complete_after_create
    community = set_community_and_has_role

    get :complete_after_create, :id => community.id

    assert_response :success
    assert_template "share/complete"
  end


  # コミュニティ作成完了画面へのアクセスを拒否チェック
  def test_access_denied_to_complete_after_create
    community = Community.make

    assert_raise Acl9::AccessDenied do
      get :complete_after_create, :id => community.id
    end

    logout

    assert_raise Acl9::AccessDenied do
      get :complete_after_create, :id => community.id
    end
  end

  # コミュニティ設定変更完了画面
  def test_complete_after_update
    community = set_community_and_has_role

    get :complete_after_update, :id => community.id

    assert_response :success
    assert_template "share/complete"
  end

  # コミュニティ設定変更完了画面へのアクセスを拒否
  def test_access_denied_to_complete_after_update
    community = Community.make

    assert_raise Acl9::AccessDenied do
      get :complete_after_update, :id => community.id
    end

    logout

    assert_raise Acl9::AccessDenied do
      get :complete_after_update, :id => community.id
    end
  end

  # コミュニティ削除完了画面
  def test_complate_after_destroy
    get :complete_after_destroy

    assert_response :success
    assert_template "share/complete"
  end

  # コミュニティ削除完了画面へのアクセスを拒否
  def test_access_denied_to_complate_after_destroy
    logout

    assert_raise Acl9::AccessDenied do
      get :complete_after_destroy
    end
  end

  # 携帯用コミュニティ詳細ページ
  def test_show_detail
    set_mobile_user_agent
    community = set_community_and_has_role(:community_category_id => 20)

    get :show_detail, :id => community

    assert_response :success
    assert_template "show_detail_mobile"
  end

  # PCから携帯用コミュニティ詳細ページへアクセス
  def test_show_detail_from_pc
    community = set_community_and_has_role(:community_category_id => 20)

    get :show_detail, :id => community

    assert_response :redirect
    assert_redirected_to "/"
  end


  # コミュニティの公開設定がSNSメンバーのみ公開になっている場合の携帯用コミュニティ詳細ページ
  # へのアクセスチェック
  def test_show_detail_with_visibility_member
    logout
    set_mobile_user_agent
    community = set_community_and_has_role(User.make,
                                           :participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:member])

    assert_raise Acl9::AccessDenied do
      get :show_detail, :id => community.id
    end
  end

  # ないしょのコミュニティは、ログインしていないとトップページが見れない
  def test_access_denied_to_secret_community
    logout
    set_mobile_user_agent
    community = Community.make(:participation_and_visibility => Community::APPROVALS_AND_VISIBILITIES[:secret])

    assert_raise Acl9::AccessDenied do
      get :show, :id => community.id
    end
  end

  # トモダチへのコミュニティを紹介メッセージ作成フォームの表示
  def test_new_message
    community = set_community_and_has_role
    get :new_message, :id => community.id

    assert_response :success
    assert_template "communities/message_form"
  end

  # トモダチへのコミュニティ紹介メッセージ作成確認画面
  def test_confirm_create_message
    community = set_community_and_has_role
    friend = User.make
    @current_user.friend! friend

    get :confirm_before_create_message, :id => community.id, :receiver_ids => ["#{friend.id}"],
         :message => Message.plan


    assert_equal assigns(:message).body, Message.plan[:body]
    assert_response :success
    assert_template "communities/message_confirm"
  end

  # トモダチへのコミュニティ紹介メッセージ作成確認画面（宛先を選択していない）
  def test_fail_to_confirm_create_message
    community = set_community_and_has_role
    friend = User.make
    @current_user.friend! friend

    get :confirm_before_create_message, :id => community.id, :receiver_ids => [],
         :message => Message.plan

    assert_match /宛先/, assigns(:message).errors.full_messages.join("\n")
    assert_response :success
    assert_template "communities/message_form"
  end

  # トモダチへのコミュニティ紹介メッセージ作成
  def test_create_message
    community = set_community_and_has_role
    friend = User.make
    @current_user.friend! friend

    assert_difference "Message.count" do
      post :create_message, :id => community.id, :receiver_ids => ["#{friend.id}"],
           :message => Message.plan
    end

    assert_equal assigns(:message).sender_id, @current_user.id
    assert_response :redirect
    assert_redirected_to complete_after_create_message_community_path(community)
  end

  # コミュニティメンバー一覧画面
  def test_show_members
    community = set_community_and_has_role
    member = User.make
    community.members << member
    member.has_role?("community_general", community)

    get :show_members, :id => community.id

    assert_response :success
    assert_template "communities/show_members"
  end

  # 参加しているコミュニティの最新書込一覧表示画面のテスト
  def test_recent_posts
    community = set_community_and_has_role
    topic = CommunityTopic.make(:community => community)

    get :recent_posts, :days_ago => 3

    assert_equal 1, assigns(:threads).size
    assert_response :success
    assert_template "communities/recent_posts"
  end

  # コミュニティをトモダチに紹介するときに、自身がコミュニティの管理人であれば、
  # 紹介された人は該当コミュニティへ招待状態となる
  def test_invite_community
    community = set_community_and_has_role(:participation_and_visibility =>
                                           Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_member])
    friend = User.make
    @current_user.friend! friend

    assert !community.invited?(friend)
    post :create_message, :receiver_ids => [friend.id], :id => community.id,
         :message => {:subject => "test subject", :body => "test body" }
    community.reload
    assert community.invited?(friend)
  end

  private

  def set_communities_for_search
    Community.destroy_all

    Community.make(:name => "カレー", :comment => "カレーの話題です",
                   :created_at => Time.now - 10,
                   :community_category_id => 21)

    Community.make(:name => "ラーメン", :comment => "ラーメン好きな人のコミュニティです",
                   :created_at => Time.now - 9,
                   :community_category_id  => 21)

    Community.make(:name => "高校野球", :comment => "高校野球を熱く語る",
                   :created_at => Time.now - 8,
                   :community_category_id => 8)

    Community.make(:name => "松江のイベント情報", :comment => "松江で開催される情報を求む",
                   :created_at => Time.now - 7,
                   :community_category_id => 20)
  end

  def set_communities_for_pagination(num = 100)
    Community.destroy_all

    num.times do |index|
      Community.make(:name => "テストコミュニティ #{index}",
                     :comment => "テストコミュニティです #{index}",
                     :community_category_id => 27)
    end
  end

  def set_communities_and_take_part_in(num = 100)
    Community.destroy_all

    num.times do |index|
      attributes = {
        :name => "テストコミュニティ #{index}",
        :comment => "テストコミュニティです #{index}",
        :community_category_id => 27,
        :approval_required => false
      }
      set_community_and_has_role("community_general", attributes)
    end
  end

  def set_official_communities
    Community.destroy_all

    Community.make(:official => Community::OFFICIALS[:normal],
                   :community_category_id => 1)
    Community.make(:official => Community::OFFICIALS[:all_member],
                   :community_category_id => 1)
    Community.make(:official => Community::OFFICIALS[:admin_only],
                   :community_category_id => 1)
  end
end

require File.dirname(__FILE__) + '/../test_helper'

# コミュニティマップカテゴリ管理テスト
class CommunityMapCategoriesControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
  end

  # 登録画面の表示
  def test_new
    get :new, :community_id => set_community_and_has_role.id

    assert_response :success
    assert_template 'community_map_categories/form'
    assert_kind_of CommunityMapCategory, assigns(:community_map_category)
  end

  # 登録データの作成
  def test_create_community_map_category
    assert_difference(['CommunityMapCategory.count']) do
      post :create, :community_map_category => CommunityMapCategory.plan,
           :community_id => set_community_and_has_role.id
    end

    community_map_category = assigns(:community_map_category)
    assert_equal CommunityMapCategory.plan[:name], community_map_category.name

    assert_response :redirect
    assert_redirected_to new_community_map_category_path(:community_id => community_map_category.community_id)
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_community_map_category_fail
    assert_no_difference(['CommunityMapCategory.count']) do
      post :create, :community_map_category => CommunityMapCategory.plan(:name => ""), :community_id => set_community_and_has_role.id
    end

    assert_template 'community_map_categories/form'
  end

  # 編集画面の表示
  def test_edit
    community = set_community_and_has_role

    get :edit, :id => CommunityMapCategory.make(:community => community).id, :community_id => community.id

    assert_response :success
    assert_template 'community_map_categories/form'
    assert_kind_of CommunityMapCategory, assigns(:community_map_category)
  end

  # 編集データの更新
  def test_update_community_map_category
    community = set_community_and_has_role
    record = CommunityMapCategory.make(:community => community)

    assert_no_difference(['CommunityMapCategory.count']) do
      put :update, :id => record.id, :community_map_category => CommunityMapCategory.plan,
          :community_id => community.id
    end

    community_map_category = assigns(:community_map_category)
    assert_equal CommunityMapCategory.plan[:name], community_map_category.name

    assert_response :redirect
    assert_redirected_to new_community_map_category_path(:community_id => community_map_category.community_id)
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_community_map_category_fail
    community = set_community_and_has_role
    record = CommunityMapCategory.make(:community => community)

    put :update, :id => record.id, :community_id => community.id,
        :community_map_category => CommunityMapCategory.plan(:name => "")

    record.reload
    assert_equal CommunityMapCategory.plan[:name], record.name

    assert_template 'community_map_categories/form'
  end

  # レコードの削除
  def test_destroy_community_map_category
    community = set_community_and_has_role
    map_category = CommunityMapCategory.make(:community => community)
    CommunityMarker.make(:community => community,
                         :map_category => map_category)

    # 削除時にこのカテゴリに属するマップがトピックになる
     assert_difference('CommunityMarker.count', -1) do
      assert_difference('CommunityTopic.count') do
        assert_difference('CommunityMapCategory.count', -1) do
          delete :destroy, :id => map_category.id, :community_id => community.id
        end
      end
    end

    assert_redirected_to new_community_map_category_path(:community_id => community.id)
  end
end

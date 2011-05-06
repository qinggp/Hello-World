require File.dirname(__FILE__) + '/../test_helper'

# お気に入り管理テスト
class FavoritesControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
  end

  # 一覧画面の表示
  def test_index
    Favorite.make(:user => @current_user)

    get :index

    assert_response :success
    assert_template 'favorites/index'
    assert_not_nil assigns(:favorites)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    assert_no_difference(['Favorite.count']) do
      post :confirm_before_create, :favorite => Favorite.plan
    end

    assert_response :success
    assert_template 'favorites/confirm'
    assert_equal true, assigns(:favorite).valid?
  end
  
  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    assert_no_difference(['Favorite.count']) do
      post :confirm_before_create, :favorite => {}
    end

    assert_response :redirect
    assert_redirected_to favorites_path
    assert_equal false, assigns(:favorite).valid?
  end

  # 登録データの作成
  def test_create_favorite
    assert_difference(['Favorite.count']) do
      post :create, :favorite => Favorite.plan(:name => "new", :url => "test/test")
    end

    favorite = Favorite.last
    assert_equal "new", favorite.name
    assert_redirected_to "test/test"
  end
  
  # 登録データの作成キャンセル
  def test_create_favorite_cancel
    assert_no_difference(['Favorite.count']) do
      post :create, :favorite => Favorite.plan(:url => "test/test"), :cancel => "Cancel"
    end

    assert_not_nil assigns(:favorite)
    assert_redirected_to 'test/test'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_favorite_fail
    assert_no_difference(['Favorite.count']) do
      post :create, :favorite => Favorite.plan(:name => "")
    end

    assert_redirected_to favorites_path
  end

  # 詳細画面の表示
  def test_show_favorite
    get :show, :id => Favorite.make(:user => @current_user).id

    assert_response :success
    assert_template 'favorites/show'
    assert_kind_of Favorite, assigns(:favorite)
  end

  # 編集画面の表示
  def test_edit
    get :edit, :id => Favorite.make(:user => @current_user).id

    assert_response :success
    assert_template 'favorites/form'
    assert_kind_of Favorite, assigns(:favorite)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    record = Favorite.make(:user => @current_user)
    post(:confirm_before_update, :id => record.id,
        :favorite => Favorite.plan)

    assert_response :success
    assert_template 'favorites/confirm'
    assert_equal true, assigns(:favorite).valid?
  end
  
  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    record = Favorite.make(:user => @current_user)
    post(:confirm_before_update, :id => record.id,
        :favorite => Favorite.plan(:name => ""))

    assert_response :success
    assert_equal false, assigns(:favorite).valid?
    assert_template 'favorites/form'
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    record = Favorite.make(:user => @current_user)
    post(:confirm_before_update, :id => record.id,
        :favorite => Favorite.plan,
        :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_favorite_path(record)
  end
  
  # 編集データの更新
  def test_update_favorite
    record = Favorite.make(:user => @current_user)

    assert_no_difference(['Favorite.count']) do
      put :update, :id => record.id, :favorite => Favorite.plan(:name => "update")
    end

    favorite = Favorite.last
    assert_equal "update", favorite.name
    assert_redirected_to complete_after_update_favorite_path(favorite)
  end
  
  # 編集データの作成キャンセル
  def test_update_favorite_cancel
    record = Favorite.make(:user => @current_user)

    put :update, :id => record.id, :favorite => Favorite.plan, :cancel => "Cancel"

    assert_not_nil assigns(:favorite)
    assert_template 'favorites/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_favorite_fail
    record = Favorite.make(:user => @current_user)

    put :update, :id => record.id, :favorite => Favorite.plan(:name => "")

    res = Favorite.find(record.id)
    assert_equal record.name, res.name
    assert_template 'favorites/form'
  end

  # レコードの削除
  def test_destroy_favorite
    target_id = Favorite.make(:user => @current_user).id
    assert_difference('Favorite.count', -1) do
      delete :destroy, :id => target_id, :back_url => "test/test"
    end
    assert_redirected_to "test/test"
  end

  # 選択レコードの削除
  def test_destroy_checked
    checked_ids = []
    2.times{ checked_ids << Favorite.make(:user => @current_user).id.to_s }

    post(:destroy_checked, :checked_ids => checked_ids)

    checked_ids.each do |id|
      assert_nil Favorite.find_by_id(id)
    end
    assert_response :redirect
  end
end

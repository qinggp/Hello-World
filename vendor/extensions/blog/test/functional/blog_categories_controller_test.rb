require File.dirname(__FILE__) + '/../test_helper'

# ブログカテゴリ管理テスト
class BlogCategoriesControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # 登録画面の表示
  def test_new
    get :new

    assert_response :success
    assert_template 'blog_categories/form'
    assert_kind_of BlogCategory, assigns(:blog_category)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    assert_no_difference(['BlogCategory.count']) do
      post :confirm_before_create, :blog_category => BlogCategory.plan
    end

    assert_response :success
    assert_template 'blog_categories/confirm'
    assert_equal true, assigns(:blog_category).valid?
  end
  
  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    assert_no_difference(['BlogCategory.count']) do
      post :confirm_before_create, :blog_category => {}
    end

    assert_response :success
    assert_template 'blog_categories/form'
    assert_equal false, assigns(:blog_category).valid?
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    post :confirm_before_create, :blog_category => {}, :clear => "Clear"

    assert_response :redirect
    assert_redirected_to new_user_blog_category_path(@current_user)
  end
  
  # 登録データの作成
  def test_create_blog_category
    assert_difference(['BlogCategory.count']) do
      post :create, :blog_category => BlogCategory.plan
    end

    @blog_category = BlogCategory.last
    assert_equal @blog_category.user_id, @current_user.id

    assert_redirected_to complete_after_create_user_blog_category_path(@current_user, @blog_category)
  end
  
  # 登録データの作成キャンセル
  def test_create_blog_category_cancel
    assert_no_difference(['BlogCategory.count']) do
      post :create, :blog_category => BlogCategory.plan, :cancel => "Cancel"
    end

    assert_not_nil assigns(:blog_category)
    assert_template 'blog_categories/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_blog_category_fail
    assert_no_difference(['BlogCategory.count']) do
      post :create, :blog_category => BlogCategory.plan(:name => "")
    end

    assert_template 'blog_categories/form'
  end

  # 詳細画面の表示
  def test_show_blog_category
    get :show, :id => BlogCategory.make.id

    assert_response :success
    assert_template 'blog_categories/show'
    assert_kind_of BlogCategory, assigns(:blog_category)
  end

  # 編集画面の表示
  def test_edit
    get :edit, :id => BlogCategory.make(:user => @current_user).id

    assert_response :success
    assert_template 'blog_categories/form'
    assert_kind_of BlogCategory, assigns(:blog_category)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    post(:confirm_before_update, :id => BlogCategory.make.id,
        :blog_category => BlogCategory.plan)

    assert_response :success
    assert_template 'blog_categories/confirm'
    assert_equal true, assigns(:blog_category).valid?
  end
  
  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    post(:confirm_before_update, :id => BlogCategory.make.id,
        :blog_category => BlogCategory.plan(:name => ""))

    assert_response :success
    assert_template 'blog_categories/form'
    assert_equal false, assigns(:blog_category).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    entry = BlogCategory.make(:user => @current_user)
    post(:confirm_before_update, :id => entry.id,
        :blog_category => BlogCategory.plan,
        :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_user_blog_category_path(@current_user, entry)
  end
  
  # 編集データの更新
  def test_update_blog_category
    record = BlogCategory.make(:user => @current_user)

    assert_no_difference(['BlogCategory.count']) do
      put :update, :id => record.id, :blog_category => BlogCategory.plan
    end

    @blog_category = BlogCategory.last
    assert_equal @blog_category.user_id, @current_user.id 

    assert_redirected_to complete_after_update_user_blog_category_path(@current_user, @blog_category)
  end
  
  # 編集データの作成キャンセル
  def test_update_blog_category_cancel
    record = BlogCategory.make(:user => @current_user)

    put :update, :id => record.id, :blog_category => BlogCategory.plan, :cancel => "Cancel"

    assert_not_nil assigns(:blog_category)
    assert_template 'blog_categories/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_blog_category_fail
    record = BlogCategory.make(:user => @current_user)

    put :update, :id => record.id, :blog_category => BlogCategory.plan(:name => "")

    assert_not_equal "", record.name

    assert_template 'blog_categories/form'
  end

  # レコードの削除
  def test_destroy_blog_category
    target_id = BlogCategory.make(:user => @current_user).id
    assert_difference('BlogCategory.count', -1) do
      delete :destroy, :id => target_id
    end

    assert_redirected_to new_user_blog_category_path(@current_user)
  end
end

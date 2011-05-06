require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CommunityCategoriesControllerTest < ActionController::TestCase
  # Replace this with your real tests.

  def setup
    #　管理者でログイン
    @current_user ||= User.make(:admin => true)
    login_as(@current_user)

    # 一覧テスト用
    # 親カテゴリ
    @parent_category = CommunityCategory.make(:name => 'parent', :parent_id => nil)
  end


  # コミュニティカテゴリの一覧のテスト
  def test_index
    get :index
   
    assert_response :success
    assert_equal 5, assigns(:community_categories).size
  end

  # コミュニティカテゴリ一覧画面で表示件数を指定したときのページネーションの結果が正しいことを確認する
  def test_index_received_per_page
    per_page = set_per_page
    get :index, :per_page => per_page

    community_categories = CommunityCategory.find(:all, :conditions => ['parent_id is null'])
    expected_total_pages = (community_categories.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:community_categories).total_pages
    assert_equal per_page, assigns(:community_categories).size
  end
  
  # コミュニティカテゴリ一覧画面でページ数を指定したときのページネーションの結果が正しいことを確認する
  def test_index_received_page
    page = set_page
    get :index, :page => page

    assert_response :success
    assert_equal page, assigns(:community_categories).current_page
  end

  # コミュニティカテゴリ一覧画面で表示件数とページ数を指定したときの
  # ページネーションの結果が正しいことを確認する
  def test_index_received_per_page_and_page
    page = set_page
    per_page = set_per_page
    10.times do |num|
      CommunityCategory.make(:name => num, :parent_id => nil)
    end
    community_categories = CommunityCategory.find(:all, :conditions => ['parent_id is null'])

    get :index, :page => page, :per_page => per_page

    expected_total_pages = (community_categories.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:community_categories).total_pages
    assert_equal page, assigns(:community_categories).current_page
    assert_equal per_page, assigns(:community_categories).size
  end

  # サブカテゴリ一覧画面のテスト
  def test_sub_category_list
    make_sub_category(5)
    get :sub_category_list, :id => @parent_category.id

    assert_response :success
    assert_equal 5, assigns(:community_categories).size

  end

  # サブカテゴリ一覧画面表示件数を指定したときのページネーションの結果が正しいことを確認する
  def test_sub_category_received_per_page
    per_page = set_per_page

    make_sub_category(5)

    get :sub_category_list, :per_page => per_page, :id => @parent_category.id

    community_categories = CommunityCategory.find(:all, :conditions => ['parent_id = ?', @parent_category.id])
    expected_total_pages = (community_categories.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:community_categories).total_pages
    assert_equal per_page, assigns(:community_categories).size
  end
  
  # サブカテゴリ一覧画面でページ数を指定したときのページネーションの結果が正しいことを確認する
  def test_sub_category_received_page
    page = set_page
    make_sub_category(10)

    get :sub_category_list, :page => page, :id => @parent_category.id

    assert_response :success
    assert_equal page, assigns(:community_categories).current_page
  end

  # サブカテゴリ一覧画面で表示件数とページ数を指定したときの
  # ページネーションの結果が正しいことを確認する
  def test_sub_category_list_received_per_page_and_page
    page = set_page
    per_page = set_per_page
    make_sub_category(10)

    community_categories = CommunityCategory.find(:all, :conditions => ['parent_id = ?', @parent_category.id])

    get :sub_category_list, :page => page, :per_page => per_page, :id => @parent_category.id

    expected_total_pages = (community_categories.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:community_categories).total_pages
    assert_equal page, assigns(:community_categories).current_page
    assert_equal per_page, assigns(:community_categories).size
  end

  # マップカテゴリの一覧のテスト
  def test_map_category_list

    5.times do
      CommunityMapCategory.make
    end

    get :map_category_list

    assert_response :success
    assert_equal 5, assigns(:community_map_categories).size
  end

  # マップカテゴリ一覧画面で表示件数を指定したときのページネーションの結果が正しいことを確認する
  def test_map_category_list_per_page
    per_page = set_per_page

    5.times do
      CommunityMapCategory.make
    end

    get :map_category_list, :per_page => per_page

    community_map_categories = CommunityMapCategory.find(:all)
    expected_total_pages = (community_map_categories.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:community_map_categories).total_pages
    assert_equal per_page, assigns(:community_map_categories).size
  end

  # マップカテゴリ一覧画面でページ数を指定したときのページネーションの結果が正しいことを確認する
  def test_map_category_list_page
    get :map_category_list, :page => 2
    
    assert_response :success
    assert_equal 2, assigns(:community_map_categories).current_page
  end

  # マップカテゴリ一覧画面で表示件数とページ数を指定したときの
  # ページネーションの結果が正しいことを確認する
  def test_map_category_list_received_per_page_and_page
    page = set_page
    per_page = set_per_page

    10.times do
      CommunityMapCategory.make
    end

    get :map_category_list, :page => page, :per_page => per_page

    community_map_categories = CommunityMapCategory.find(:all)
    expected_total_pages = (community_map_categories.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:community_map_categories).total_pages
    assert_equal page, assigns(:community_map_categories).current_page
    assert_equal per_page, assigns(:community_map_categories).size
  end

    # コミュニティカテゴリ新規作成画面
  def test_new
    get :new

    assert_response :success
    assert_template :"form"
  end

  # サブカテゴリ新規作成画面(カテゴリ選択可能画面)
  def test_sub_category_new_unselected_category

    get :sub_category_new

    assert_response :success
    assert_equal '0', assigns(:category_state_id)
    assert_template :"form"
  end

  # サブカテゴリ新規作成画面(カテゴリ選択済み画面）
  def test_sub_category_new_selected_category
    community_category = community_categories(:life)

    get :sub_category_new ,:category_state_id => community_category.id

    assert_response :success
    assert_equal community_category.id, assigns(:community_category).parent_id
    assert_equal community_category.id, assigns(:selected_category).id
    assert_template :"form"
  end

  # コミュニティカテゴリ変更画面
  def test_edit
    community_category = set_community_category

    get :edit, :id => community_category.id

    assert_response :success
    assert_template :"form"
  end

  # サブカテゴリ変更画面
  def test_sub_category_edit
    community_category = set_community_category

    get :sub_category_edit, :id => community_category.id

    assert_response :success
    assert_equal '0', assigns(:category_state_id)
    assert_template :"form"
  end

  # マップカテゴリ変更画面
  def test_map_category_edit
    community_map_category = community_map_categories(:curry_shop)

    get :map_category_edit, :id => community_map_category.id

    assert_response :success

  end

  # コミュニティカテゴリ新規作成確認画面
  def test_confirm_before_create
    community_category = community_categories(:life)
    attributes =
      CommunityCategory.plan(:name => community_category.name,
                             :parent_id => nil)

    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_create, :community_category => attributes
    end

    assert_response :success
    assert_template :"confirm"

    attributes.each do |attribute, value|
      assert_equal value, assigns(:community_category).send(attribute)
    end
  end

  # コミュニティカテゴリ新規作成「全てクリアボタン」
  def test_confirm_before_create_clear
    community_category = community_categories(:life)
    attributes =
      CommunityCategory.plan(:name => community_category.name,
                             :parent_id => nil)

    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_create,
           :community_category => attributes,
           :clear => '全てクリア'
    end

    assert_template :"form"

  end

  # コミュニティカテゴリ新規作成エラー
  def test_confirm_before_create_error
    attributes =
      CommunityCategory.plan(:name => nil,
                             :parent_id => nil)

    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_create,
           :community_category => attributes
    end

    assert !assigns(:community_category).valid?
    assert_template :"form"

  end

  # サブカテゴリ新規作成確認画面
  def test_sub_category_confirm_before_create
    community_category = community_categories(:music)
    attributes =
      CommunityCategory.plan(:name => community_category.name,
                             :parent_id => community_category.parent_id)

    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_create,
           :community_category => attributes,
           :selected_category => community_category.parent_id
    end

    assert_response :success
    assert_template :"confirm"

    attributes.each do |attribute, value|
      assert_equal value, assigns(:community_category).send(attribute)
    end
  end

  # サブカテゴリ新規作成「全てクリア」ボタン
  def test_sub_category_confirm_before_create_clear
    community_category = community_categories(:music)
    attributes =
      CommunityCategory.plan(:name => community_category.name,
                             :parent_id => community_category.parent_id)

    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_create,
           :community_category => attributes,
           :selected_category => community_category.parent_id,
           :clear => '全てクリア'
    end
    assert_template :"form"
  end

  # サブカテゴリ新規作成エラー
  def test_sub_category_confirm_before_create_error
    community_category = community_categories(:music)
    attributes = {:name => nil,
                  :parent_id => community_category.parent_id
    }
    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_create,
           :community_category => attributes
    end
    assert !assigns(:community_category).valid?
    assert_template :"form"
  end

  # コミュニティカテゴリ変更確認画面
  def test_confirm_before_update
    community_category = community_categories(:life)

    updating_attributes = {
      :id => community_category.id,
      :name => "テストカテゴリコミュニティ",
      :parent_id => nil

    }

    current_attributes = CommunityCategory.plan

    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_update,
           :id => community_category.id,
           :community_category => updating_attributes,
           :selected_category => '0'
    end

    assert_response :success
    assert_template :"confirm"

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, assigns(:community_category).send(attribute)
    end
  end

  # コミュニティカテゴリ変更「全てクリア」ボタン
  def test_confirm_before_update_clear
    community_category = community_categories(:life)

    updating_attributes = {
      :id => community_category.id,
      :name => "テストカテゴリコミュニティ",
      :parent_id => nil
    }

    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_update,
           :id => community_category.id,
           :community_category => updating_attributes,
           :selected_category => '0',
           :clear => '全てクリア'
    end
    assert_template :"form"
  end

  # コミュニティカテゴリ変更エラー
  def test_confirm_before_update_error
    community_category = community_categories(:life)
    updating_attributes = {
      :id => community_category.id,
      :name => nil,
      :parent_id => nil
    }
    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_update,
           :id => community_category.id,
           :community_category => updating_attributes,
           :selected_category => '0'
    end
    assert !assigns(:community_category).valid?
    assert_template :"form"
  end

  # サブカテゴリ変更確認画面
  def test_sub_category_confirm_before_update
    community_category = community_categories(:music)
    parent_category = community_categories(:life)

    updating_attributes = {
      :id => community_category.id,
      :name => "テストカテゴリコミュニティ",
      :parent_id => parent_category.id

    }

    current_attributes = CommunityCategory.plan

    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_update,
           :id => community_category.id,
           :community_category => updating_attributes,
           :selected_category => parent_category.id
    end

    assert_response :success
    assert_template :"confirm"

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, assigns(:community_category).send(attribute)
    end

    assert_equal expected_attributes[:parent_id], assigns(:community_category).parent_id
    assert_equal expected_attributes[:parent_id], assigns(:parent_category).id
  end

  # サブカテゴリ変更「全てクリア」ボタン
  def test_sub_category_confirm_before_update_clear
    community_category = community_categories(:music)
    parent_category = community_categories(:life)

    updating_attributes = {
      :id => community_category.id,
      :name => "テストカテゴリコミュニティ",
      :parent_id => parent_category.id
    }

#    current_attributes = CommunityCategory.plan

    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_update,
           :id => community_category.id,
           :community_category => updating_attributes,
           :selected_category => parent_category.id,
           :clear => '全てクリア'
    end

    assert_template :"form"
  end

  # サブカテゴリ変更エラー
  def test_confirm_before_update_error
    community_category = community_categories(:music)
    parent_category = community_categories(:life)

    updating_attributes = {
      :id => community_category.id,
      :name => nil,
      :parent_id => community_category.parent_id
    }
    assert_no_difference "CommunityCategory.count" do
      post :confirm_before_update,
           :id => community_category.id,
           :community_category => updating_attributes,
           :selected_category => parent_category.id
    end
    assert !assigns(:community_category).valid?
    assert_template :"form"
  end

  # マップカテゴリ変更確認画面
  def test_map_category_confirm_before_update
    community_map_category = community_map_categories(:curry_shop)

    updating_attributes = {
      :user_id => community_map_category.user_id,
      :name => "テストカテゴリコミュニティ",
      :community_id => community_map_category.community_id
    }

    current_attributes = CommunityMapCategory.plan

    assert_no_difference "CommunityMapCategory.count" do
      post :map_category_confirm_before_update,
           :id => community_map_category.id,
           :community_map_category => updating_attributes
    end

    assert_response :success
    assert_template :"confirm"

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, assigns(:community_map_category).send(attribute)
    end

  end

  # マップカテゴリ変更「全てクリア」ボタン
  def test_map_category_confirm_before_update_clear
    community_map_category = community_map_categories(:curry_shop)

    updating_attributes = {
      :user_id => community_map_category.user_id,
      :name => "テストカテゴリコミュニティ",
      :community_id => community_map_category.community_id
    }
    assert_no_difference "CommunityMapCategory.count" do
      post :map_category_confirm_before_update,
           :id => community_map_category.id,
           :community_map_category => updating_attributes,
           :clear => '全てクリア'
    end
    assert_redirected_to :controller => 'admin/community_categories', :action => 'map_category_edit'
  end

  # マップカテゴリ変更エラー
  def test_map_confirm_before_update_error
    community_map_category = community_map_categories(:curry_shop)
    updating_attributes = {
      :id => community_map_category.id,
      :name => nil
    }
    assert_no_difference "CommunityCategory.count" do
      post :map_category_confirm_before_update,
           :id => community_map_category.id,
           :community_map_category => updating_attributes
    end
    assert !assigns(:community_map_category).valid?
    assert_template :"form"
  end

  # コミュニティカテゴリ作成後、コミュニティカテゴリ作成完了画面
  def test_create
    community_category = community_categories(:life)
    attributes =
      CommunityCategory.plan(:name => community_category.name,
                             :parent_id => nil)

    assert_difference "CommunityCategory.count" do
      post :create, :community_category => attributes
    end

    community_category = assigns(:community_category)
    assert_response :redirect
    assert_redirected_to complete_after_create_admin_community_category_path(:id => community_category.id)
    assert "作成完了いたしました", assigns(:message)

    attributes.each do |attribute, value|
      assert_equal value, community_category.send(attribute)
    end
  end

  # コミュニティカテゴリ作成「入力画面へ戻る」ボタン
  def test_create_cancel
    community_category = community_categories(:life)
    attributes =
      CommunityCategory.plan(:name => community_category.name,
                             :parent_id => nil)

    assert_no_difference "CommunityCategory.count" do
      post :create, :community_category => attributes,
           :cancel => '入力画面へ戻る'
    end
    assert_template :"form"
  end

  # サブカテゴリ作成後、サブカテゴリ作成完了画面
  def test_sub_category_create
    community_category = community_categories(:music)
    attributes =
      CommunityCategory.plan(:name => community_category.name,
                             :parent_id => community_category.parent_id)

    assert_difference "CommunityCategory.count" do
      post :create, :community_category => attributes
    end

    community_category = assigns(:community_category)
    assert_response :redirect
    assert_redirected_to complete_after_create_admin_community_category_path(:id => community_category.id)
    assert "作成完了いたしました", assigns(:message)

    attributes.each do |attribute, value|
      assert_equal value, community_category.send(attribute)
    end
  end

  # サブカテゴリ作成「入力画面へ戻る」ボタン
  def test_sub_category_create_cancel
    community_category = community_categories(:music)
    attributes =
      CommunityCategory.plan(:name => community_category.name,
                             :parent_id => community_category.parent_id)

    assert_no_difference "CommunityCategory.count" do
      post :create, :community_category => attributes,
           :cancel => '入力画面へ戻る'
    end
    assert_template :"form"
  end

  #  コミュニティカテゴリ設定変更後、コミュニティカテゴリ設定変更完了画面
  def test_update
    community_category = community_categories(:life)
    updating_attributes = {
      :name => "テストカテゴリコミュニティ",
      :parent_id => nil
    }
    current_attributes = CommunityCategory.plan

    assert_no_difference "CommunityCategory.count" do
      put :update, :id => community_category.id, :community_category => updating_attributes
    end


    community_category.reload
    assert_response :redirect
    assert_redirected_to complete_after_update_admin_community_category_path(community_category.id)
    assert "修正完了いたしました", assigns(:message)

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, community_category.send(attribute)
    end
  end

  #  コミュニティカテゴリ設定変更「入力画面へ戻る」ボタン
  def test_update_cancel
    community_category = community_categories(:life)
    updating_attributes = {
      :name => "テストカテゴリコミュニティ",
      :parent_id => nil
    }

    assert_no_difference "CommunityCategory.count" do
      put :update, :id => community_category.id,
          :community_category => updating_attributes, :cancel => '入力画面へ戻る'
    end

    community_category.reload
    assert_template :"form"
  end

  # サブカテゴリ設定変更後、サブカテゴリ変更完了画面
  def test_sub_category_update
    community_category = community_categories(:music)
      updating_attributes = {
        :name => "テストカテゴリコミュニティ",
        :parent_id => community_category.parent_id
      }
      current_attributes = CommunityCategory.plan

      assert_no_difference "CommunityCategory.count" do
        put :update, :id => community_category.id, :community_category => updating_attributes
      end

      community_category.reload
      assert_response :redirect
      assert_redirected_to complete_after_update_admin_community_category_path(community_category.id)
      assert "修正完了いたしました", assigns(:message)

      expected_attributes =
        current_attributes.update(updating_attributes)
      expected_attributes.each do |attribute, value|
        assert_equal value, community_category.send(attribute)
      end
  end

   # サブカテゴリ設定変更「入力画面へ戻る」ボタン
  def test_sub_category_update_cancel
    community_category = community_categories(:music)
      updating_attributes = {
        :name => "テストカテゴリコミュニティ",
        :parent_id => community_category.parent_id
      }
      assert_no_difference "CommunityCategory.count" do
        put :update, :id => community_category.id,
            :community_category => updating_attributes, :cancel => '入力画面へ戻る'
      end

      community_category.reload
      assert_template :"form"
  end

  # マップカテゴリ設定変更後、マップカテゴリ変更完了画面
  def test_map_category_update
    community_map_category = community_map_categories(:curry_shop)
      updating_attributes = {
        :name => "テストマップカテゴリ",
        :user_id => community_map_category.user_id,
        :community_id => community_map_category.community_id
      }
      current_attributes = CommunityMapCategory.plan

      assert_no_difference "CommunityMapCategory.count" do
        put :map_category_update, :id => community_map_category.id, :community_map_category => updating_attributes
      end

      community_map_category.reload
      assert_response :redirect
      assert_redirected_to complete_after_update_admin_community_category_path(community_map_category.id)
      assert "修正完了いたしました", assigns(:message)

      expected_attributes =
        current_attributes.update(updating_attributes)
      expected_attributes.each do |attribute, value|
        assert_equal value, community_map_category.send(attribute)
      end
  end

  # マップカテゴリ変更「入力画面へ戻る」ボタン
  def test_map_category_update_cancel
    community_map_category = community_map_categories(:curry_shop)
      updating_attributes = {
        :name => "テストマップカテゴリ",
        :user_id => community_map_category.user_id,
        :community_id => community_map_category.community_id
      }
      assert_no_difference "CommunityMapCategory.count" do
        put :map_category_update, :id => community_map_category.id,
            :community_map_category => updating_attributes, :cancel => '入力画面へ戻る'
      end
      community_map_category.reload
      assert_template :"form"
  end

  private

  # 表示件数をセットする
  def set_per_page
    5
  end

  # ページを設定する
  def set_page
    2
  end
 
  # @parent_categoryを親にもつサブカテゴリの作成
  # 引数の値の数だけ作成
  def make_sub_category(num)
    num.to_i.times do |number|
      CommunityCategory.make(:name => number, :parent_id => @parent_category.id)
    end

  end

  def set_community_category
    CommunityCategory.make(:name => 'テストデータ')

  end


end

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::BannersControllerTest < ActionController::TestCase

  def setup
    #　管理者でログイン
    @current_user ||= users(:sns_tarou)
    login_as(@current_user)
  end

  # バナー管理一覧画面のテスト
  def test_index
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    10.times do
      Banner.make(:link_url => nil,
                  :image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    end
    page = set_page
    per_page = set_per_page
    banners = Banner.find(:all)

    # 条件なし
    get :index

    assert_response :success
    assert_equal 5, assigns(:banners).size

    # 表示件数指定
    get :index, :per_page => per_page

    expected_total_pages = (banners.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:banners).total_pages
    assert_equal 1, assigns(:banners).current_page
    assert_equal per_page, assigns(:banners).size

    # ページ指定
    get :index, :page => page

    assert_response :success
    assert_equal page, assigns(:banners).current_page

    # 表示件数、ページ指定
    get :index, :page => page, :per_page => per_page

    expected_total_pages = (banners.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:banners).total_pages
    assert_equal page, assigns(:banners).current_page
    assert_equal per_page, assigns(:banners).size

  end

 
  # バナー新規作成画面
  def test_new
    get :new

    assert_response :success
    assert_template :"form"
  end
  
  # バナー変更画面
  def test_edit
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    banner = Banner.make(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    get :edit, :id => banner.id

    assert_response :success
    assert_template :"form"
  end

  # バナー新規作成確認画面
  def test_confirm_before_create
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    banner = Banner.make(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    attributes = Banner.plan(:comment => banner.comment,
                             :link_url => banner.link_url,
                             :expire_date => 2.days.ago)
    assert_no_difference "Banner.count" do
      post :confirm_before_create,
           :banner => attributes.merge!(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    end

    assert_response :success
    assert_template :"confirm"
  end

  # バナー新規作成「全てクリア」ボタン
  def test_confirm_before_create_clear
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    banner = Banner.make(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    attributes = Banner.plan(:comment => banner.comment,
                             :link_url => banner.link_url,
                             :expire_date => 2.days.ago)
    assert_no_difference "Banner.count" do
      post :confirm_before_create,
           :banner => attributes,
           :clear => '全てクリア'
    end
    assert_redirected_to new_admin_banner_path

  end

  # バナー新規作成エラー
  def test_confirm_before_create_error
    attributes = Banner.plan(:comment => nil,
                             :link_url => nil,
                             :expire_date => 2.days.ago)
    assert_no_difference "Banner.count" do
      post :confirm_before_create,
           :banner => attributes
    end
    assert_equal false, assigns(:banner).valid?
    assert_template :"form"
  end


  # バナー変更確認画面
  def test_confirm_before_update
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    banner = Banner.make(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    updating_attributes = {
      :id => banner.id,
      :comment => banner.comment,
      :link_url => banner.link_url,
      :expire_date => 2.days.ago
    }
    current_attributes = Banner.plan
    assert_no_difference "Banner.count" do
      post :confirm_before_update,
           :id => banner.id,
           :banner => updating_attributes.merge(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    end
    assert_response :success
    assert_template :"confirm"

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, assigns(:banner).send(attribute)
    end
  end

  # バナー変更「全てクリア」ボタン
  def test_confirm_before_update_clear
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    banner = Banner.make(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    updating_attributes = {
      :id => banner.id,
      :comment => banner.comment,
      :link_url => banner.link_url,
      :expire_date => 2.days.ago
    }
    assert_no_difference "Banner.count" do
      post :confirm_before_update,
           :id => banner.id,
           :banner => updating_attributes,
           :clear => '全てクリア'
    end
    assert_redirected_to edit_admin_banner_path(banner)

  end

  # バナー変更エラー
  def test_confirm_before_update_clear
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    banner = Banner.make(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    updating_attributes = {
      :id => banner.id,
      :comment => nil,
      :link_url => nil,
      :expire_date => 2.days.ago
      }
    assert_no_difference "Banner.count" do
      post :confirm_before_update,
           :id => banner.id,
           :banner => updating_attributes
    end
    assert_equal false, assigns(:banner).valid?
    assert_template :"form"

  end

  # バナー作成後、バナー作成完了画面
  # confirm_before_createをしてから
  # createをすることによって、ファイルのアップロードを確認している
  def test_create
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    banner = Banner.make(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    
    attributes = Banner.plan(:comment => banner.comment,
                             :link_url => banner.link_url,
                             :expire_date => 2.days.ago)
    post :confirm_before_create, :banner => attributes.merge!(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))


    create_attributes = Banner.plan(:comment => banner.comment,
                                    :link_url => banner.link_url,
                                    :expire_date => 2.days.ago)
    assert_difference "Banner.count" do
      post :create, :banner => create_attributes.merge(:image_temp => assigns(:banner).image_temp)
    end

    banner = assigns(:banner)
    assert_response :redirect
    assert_redirected_to complete_after_create_admin_banner_path(:id => banner.id)

    create_attributes.each do |attribute, value|
      assert_equal value, banner.send(attribute)
    end
  end

  # バナー作成「入力画面へ戻る」ボタン
  def test_create_cancel
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    banner = Banner.make(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    attributes = Banner.plan(:comment => banner.comment,
                             :link_url => banner.link_url,
                             :expire_date => 2.days.ago)

    assert_no_difference "Banner.count" do
      post :create, :banner => attributes, :cancel => '入力画面へ戻る'
    end
    assert_template :"form"
  end

  # バナー変更後、バナー変更完了画面
  # confirm_before_updateをしてから
  # updateをすることによって、ファイルのアップロードを確認している
  def test_update
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    banner = Banner.make(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    attributes = {
      :id => banner.id,
      :comment => banner.comment,
      :link_url => banner.link_url,
      :expire_date => 2.days.ago
    }
    current_attributes = Banner.plan
    post :confirm_before_update,
         :id => banner.id,
         :banner => attributes.merge!(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    updating_attributes = {
      :comment => "テストコメント",
      :link_url => banner.link_url,
      :expire_date => 2.days.ago
    }
    current_attributes = Banner.plan

    assert_no_difference "Banner.count" do
      put :update, :id => assigns(:banner).id, :banner => updating_attributes.merge(:image_temp => assigns(:banner).image_temp)
    end

    banner.reload
    assert_response :redirect
    assert_redirected_to complete_after_update_admin_banner_path(assigns(:banner).id)
    assert "修正完了いたしました", assigns(:message)

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, banner.send(attribute)
    end
  end

  # バナー変更「入力画面へ戻る」ボタン
  def test_update_cancel
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    banner = Banner.make(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    updating_attributes = {
      :comment => "テストコメント",
      :link_url => banner.link_url,
      :expire_date => 2.days.ago
    }
    assert_no_difference "Banner.count" do
      put :update,
          :id => banner.id,
          :banner => updating_attributes,
          :cancel => '入力画面へ戻る'
    end
    banner.reload

    assert_template :"form"
  end

  # レコードの削除
  def test_destroy
    file_name = upload_test_file
    upload_file_type = set_upload_file_type
    banner = Banner.make(:image => fixture_file_upload("test_image/#{file_name}",upload_file_type))
    assert_difference('Banner.count', -1) do
      delete :destroy, :id => banner.id
    end
    assert_redirected_to admin_banners_path
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

  # idをセットする
  def set_id
    1
  end

  def upload_test_file
    'test_rails.gif'
  end

  def set_upload_file_type
    'image/gif'
  end

end

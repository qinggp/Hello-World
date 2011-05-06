require File.dirname(__FILE__) + '/../../test_helper'

# ページ管理テスト
class Admin::PagesControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make(:admin => true)
    login_as(@current_user)

    # アップロード用のテスト画像名
    @upload_image_name = 'test_rails.png'
    @upload_image_path = 'images/test_rails.png'
    
    # アップロード可能な画像の種類(testのためにpngのみ）
    @upload_image_type = "image/png"
    # アップロード先のpath
    @upload_path = Admin::PagesController::IMAGE_MANAGEMENT_PATH
    # アップロード前のファイル位置
    @before_upload_path = "test_image"
    # 上書きテスト用の画像位置
    @overwrite_upload_image_name = "test_image/overwrite"

  end

  # 一覧画面の表示
  def test_index
    get :index

    assert_response :success
    assert_template 'admin/pages/index'
    assert_not_nil assigns(:pages)
  end

   # ページ管理一覧画面で表示件数を指定したときのページネーションの結果が正しいことを確認する
  def test_index_received_per_page
    per_page = set_per_page
    get :index, :per_page => per_page

    pages = Page.find(:all)
    expected_total_pages = (pages.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:pages).total_pages
    assert_equal 1, assigns(:pages).current_page
    assert_equal set_per_page, assigns(:pages).size

  end

  # ページ管理一覧画面でページ数をしていたときのページネーションの結果が正しいことを確認する
  def test_index_received_page
    page = set_page
    get :index, :page => page

    assert_response :success
    assert_equal page, assigns(:pages).current_page
  end

  # ページ管理一覧画面で表示件数とページ数を指定したときの
  # ページネーションの結果が正しいことを確認する
  def test_index_received_per_page_and_page
    page, per_page = set_page, 1
    pages = Page.find(:all)

    get :index, :page => page, :per_page => per_page

    expected_total_pages = (pages.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:pages).total_pages
    assert_equal page, assigns(:pages).current_page
    assert_equal per_page, assigns(:pages).size
  end

  # ページ管理編集画面
  def test_edit
    page = pages(:about)
    get :edit, :id => page.id

    assert_response :success
    assert_template :"form"
  end

  # ページ管理編集確認画面
  def test_confirm_before_update
    page = pages(:about)
    updating_attributes = {
      :id => page.id,
      :title => page.title,
      :body => page.body,
      :page_id => page.page_id
    }
    current_attributes = Page.plan
    assert_no_difference "Page.count" do
      post :confirm_before_update,
           :id => page.id,
           :page => updating_attributes
    end
    assert_response :success
    assert_template :"confirm"

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, assigns(:page).send(attribute)
    end
  end

  # ページ管理変更「全てクリア」ボタン
  def test_confirm_before_update_clear
    page = pages(:about)
    updating_attributes = {
      :id => page.id,
      :title => page.title,
      :body => page.body,
      :page_id => page.page_id
    }
    assert_no_difference "Page.count" do
      post :confirm_before_update,
           :id => page.id,
           :page => updating_attributes,
           :clear => '全てクリア'
    end
    assert_redirected_ro edit_admin_page_path(page)
  end

  # ページ管理変更エラー
  def test_confirm_before_update_clear
    page = pages(:about)
    updating_attributes = {
      :id => page.id,
      :title => page.title,
      :body => nil,
      :page_id => page.page_id
    }
    assert_no_difference "Page.count" do
      post :confirm_before_update,
           :id => page.id,
           :page => updating_attributes
    end
    assert !assigns(:page).valid?
    assert_template :"form"

  end

  # ページ変更完了画面
  def test_update
    page = pages(:about)
    updating_attributes = {
      :title => page.title,
      :body => page.body,
      :page_id => page.page_id
    }
    current_attributes = Page.plan
    assert_no_difference "Page.count" do
      put :update,
          :id => page.id,
          :page => updating_attributes
    end
    page.reload
    assert_response :redirect
    assert_redirected_to complete_after_update_admin_page_path(assigns(:page))
    assert "修正完了いたしました", assigns(:message)

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, page.send(attribute)
    end
  end

  # ページ管理変更「入力画面へ戻る」ボタン
  def test_update_cancel
    page = pages(:about)
    updating_attributes = {
      :title => page.title,
      :body => page.body,
      :page_id => page.page_id
    }
    assert_no_difference "Page.count" do
      put :update,
          :id => page.id,
          :page => updating_attributes,
          :cancel => '入力画面へ戻る'
    end
    page.reload

    assert_template :"form"
  end

  # 画像の一覧の表示
  def test_image_management
    get :image_management
    assert_response :success
    assigns(:images).each do |image|
      assert File.exist?(File.join(Rails.public_path, image))
    end
  end

  # 画像のアップロードと削除
  # テスト用の画像をアップロードし、そのファイルの削除を行う
  def test_image_destroy_and_upload
    # 既に同名ファイルが存在する場合削除する
    if File.exist?("#{@upload_path}/#{@upload_image_name}")
      get :image_destroy, :filename => File.join("images", @upload_image_name)
    end
    
    # ファイルのアップロード処理
    assert_difference 'set_file.size' do
      post :image_upload,
           :upload => fixture_file_upload("#{@before_upload_path}/#{@upload_image_name}", @upload_image_type),
           :upload_path => @upload_image_path
    end
    assert File.exist?("#{@upload_path}/#{@upload_image_name}")
    assert_redirected_to image_management_admin_pages_path

    # ファイルの削除処理
    assert_difference 'set_file.size', -1  do
      get :image_destroy, :filename => File.join("images", @upload_image_name)
    end

    assert !File.exist?("#{@upload_path}/#{@upload_image_name}")
    assert_redirected_to image_management_admin_pages_path
  end

  # 同じファイル名のデータをアップロードするとき
  # チェックボックスにチェックをしていないと
  # 上書きできないことをテスト
  def test_upload_overwrite
    # 既に同名ファイルがあった場合ファイルを削除する
    if File.exist?("#{@upload_path}/#{@upload_image_name}")
      get :image_destroy, :filename => File.join("images", @upload_image_name)
    end

    # アップロード処理
    assert_difference 'set_file.size' do
      post :image_upload, :upload => fixture_file_upload("#{@before_upload_path}/#{@upload_image_name}", @upload_image_type), :upload_path => @upload_image_path
    end

    #上書き不可の状態でのアップロード処理
    post :image_upload,
         :upload => fixture_file_upload("#{@overwrite_upload_image_name}/#{@upload_image_name}", @upload_image_type),
         :upload_path => @upload_image_path
    assert FileUtils.cmp("#{@upload_path}/#{@upload_image_name}", "test/fixtures/#{"#{@before_upload_path}/#{@upload_image_name}"}")
    assert !FileUtils.cmp("#{@upload_path}/#{@upload_image_name}", "test/fixtures/#{@overwrite_upload_image_name}")

    #上書き可の状態でのアップロード処理
    post :image_upload,
         :upload => fixture_file_upload("#{@overwrite_upload_image_name}/#{@upload_image_name}", @upload_image_type),
         :overwrite => 1,
         :upload_path => @upload_image_path
    assert !FileUtils.cmp("#{@upload_path}/#{@upload_image_name}", "test/fixtures/#{"#{@before_upload_path}/#{@upload_image_name}"}")
    assert FileUtils.cmp("#{@upload_path}/#{@upload_image_name}", "test/fixtures/#{@overwrite_upload_image_name}/#{@upload_image_name}")

    get :image_destroy, :filename => File.join("images", @upload_image_name)
    
  end

  # ファイルのアップロードエラーチェック（拡張子）
  def image_upload_failed
    file_name = "test_rails.text"
    # 既に同名ファイルがあった場合ファイルを削除する
    if File.exist?("#{@upload_path}/#{file_name}")
      get :image_destroy, :filename => File.join("images", file_name)
    end
    
    post :image_upload,
         :upload => fixture_file_upload("#{@before_upload_path}/#{file_name}"),
         :upload_path => @upload_image_path
    assert !File.exist?("#{@upload_path}/#{file_name}")

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

  # エラーデータの設定
  def error_data_set
   [:title => nil,
     :page_id => nil,
     :body => nil]
  end

  # 画像のセット
  def set_file
    images_data = Dir.glob("#{@upload_path}/*.*")
  end

  # アップロード用のテスト画像
  def set_upload_test_file
    'test_rails.png'
  end

 # アップロード可能な画像の種類
  def set_upload_file_type
    'image/png'
  end

  # アップロード先のpath
  def set_public_file_path(file_name)
    "#{Admin::PagesController::IMAGE_MANAGEMENT_PATH}/#{file_name}"
  end


  def set_before_upload_file_path(file_name)
    "test_image/#{file_name}"
  end

  #上書きするファイルのpath
  def set_overwrite_file_path(file_name)
    "test_image/overwrite/#{file_name}"
  end

end

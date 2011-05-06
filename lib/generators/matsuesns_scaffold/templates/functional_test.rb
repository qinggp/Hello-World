require File.dirname(__FILE__) + '/../test_helper'

# <%= controller_class_name %>管理テスト（FIXME: 日本語名を書く）
class <%= controller_class_name %>ControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
  end

  # 一覧画面の表示
  def test_index
    get :index

    assert_response :success
    assert_template '<%= class_nesting_with_slash %><%= table_name %>/index'
    assert_not_nil assigns(:<%= table_name %>)
  end

  # 登録画面の表示
  def test_new
    get :new

    assert_response :success
    assert_template '<%= class_nesting_with_slash %><%= table_name %>/form'
    assert_kind_of <%= class_name %>, assigns(:<%= file_name %>)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    assert_no_difference(['<%= class_name %>.count']) do
      post :confirm_before_create, :<%= file_name %> => <%= class_name %>.plan
    end

    assert_response :success
    assert_template '<%= class_nesting_with_slash %><%= table_name %>/confirm'
    assert_equal true, assigns(:<%= file_name %>).valid?
  end
  
  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    # FIXME 不正な登録データを送信する．
    assert_no_difference(['<%= class_name %>.count']) do
      post :confirm_before_create, :<%= file_name %> => <%= class_name %>.plan()
    end

    assert_response :success
    assert_template '<%= class_nesting_with_slash %><%= table_name %>/form'
    assert_equal false, assigns(:<%= file_name %>).valid?
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    post :confirm_before_create, :<%= file_name %> => {}, :clear => "Clear"

    assert_response :redirect
    assert_redirected_to new_<%= file_name %>_path
  end
  
  # 登録データの作成
  def test_create_<%= file_name %>
    assert_difference(['<%= class_name %>.count']) do
      post :create, :<%= file_name %> => <%= class_name %>.plan
    end

    # FIXME: 作成したレコード内容の検証を行う
    @<%= file_name %> = <%= class_name %>.last

    assert_redirected_to complete_after_create_<%= file_name %>_path(@<%= file_name %>)
  end
  
  # 登録データの作成キャンセル
  def test_create_<%= file_name %>_cancel
    assert_no_difference(['<%= class_name %>.count']) do
      post :create, :<%= file_name %> => <%= class_name %>.plan, :cancel => "Cancel"
    end

    assert_not_nil assigns(:<%= file_name %>)
    assert_template '<%= class_nesting_with_slash %><%= table_name %>/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_<%= file_name %>_fail
    # FIXME: 不正なデータを送信する
    assert_no_difference(['<%= class_name %>.count']) do
      post :create, :<%= file_name %> => <%= class_name %>.plan()
    end

    assert_template '<%= class_nesting_with_slash %><%= table_name %>/form'
  end

  # 詳細画面の表示
  def test_show_<%= file_name %>
    get :show, :id => <%= class_name %>.make.id

    assert_response :success
    assert_template '<%= class_nesting_with_slash %><%= table_name %>/show'
    assert_kind_of <%= class_name %>, assigns(:<%= file_name %>)
  end

  # 編集画面の表示
  def test_edit
    get :edit, :id => <%= class_name %>.make.id

    assert_response :success
    assert_template '<%= class_nesting_with_slash %><%= table_name %>/form'
    assert_kind_of <%= class_name %>, assigns(:<%= file_name %>)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    post(:confirm_before_update, :id => <%= class_name %>.make.id,
        :<%= file_name %> => <%= class_name %>.plan)

    assert_response :success
    assert_template '<%= class_nesting_with_slash %><%= table_name %>/confirm'
    assert_equal true, assigns(:<%= file_name %>).valid?
  end
  
  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    # FIXME 不正な更新データを送信する．
    post(:confirm_before_update, :id => <%= class_name %>.make.id,
        :<%= file_name %> => <%= class_name %>.plan(  ))

    assert_response :success
    assert_template '<%= class_nesting_with_slash %><%= table_name %>/form'
    assert_equal false, assigns(:<%= file_name %>).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    entry = <%= class_name %>.make
    post(:confirm_before_update, :id => entry.id,
        :<%= file_name %> => <%= class_name %>.plan,
        :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_<%= file_name %>_path(entry)
  end
  
  # 編集データの更新
  def test_update_<%= file_name %>
    record = <%= class_name %>.make

    assert_no_difference(['<%= class_name %>.count']) do
      put :update, :id => record.id, :<%= file_name %> => <%= class_name %>.plan
    end

    # FIXME: 更新したレコード内容の検証を行う
    @<%= file_name %> = <%= class_name %>.last

    assert_redirected_to complete_after_update_<%= file_name %>_path(@<%= file_name %>)
  end
  
  # 編集データの作成キャンセル
  def test_update_<%= file_name %>_cancel
    record = <%= class_name %>.make

    put :update, :id => record.id, :<%= file_name %> => <%= class_name %>.plan, :cancel => "Cancel"

    assert_not_nil assigns(:<%= file_name %>)
    assert_template '<%= class_nesting_with_slash %><%= table_name %>/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_<%= file_name %>_fail
    record = <%= class_name %>.make

    # FIXME: 不正なデータを登録する
    put :update, :id => record.id, :<%= file_name %> => <%= class_name %>.plan( )

    # FIXME: レコードが更新されていないことを検証する．

    assert_template '<%= class_nesting_with_slash %><%= table_name %>/form'
  end

  # レコードの削除
  def test_destroy_<%= file_name %>
    target_id = <%= class_name %>.make.id
    assert_difference('<%= class_name %>.count', -1) do
      delete :destroy, :id => target_id
    end

    assert_redirected_to <%= plural_name_with_nesting %>_path
  end
  
  # レコードの削除の失敗
  def test_destroy_<%= file_name %>_fail
    # FIXME: 削除時に制約が無い場合はこのメソッドを削除してください．
    target_id = <%= table_name %>.make.id
    assert_no_difference('<%= class_name %>.count') do
      delete :destroy, :id => target_id
    end

    assert_redirected_to <%= plural_name_with_nesting %>_path
  end
end

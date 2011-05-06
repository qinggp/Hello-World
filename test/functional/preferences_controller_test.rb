require File.dirname(__FILE__) + '/../test_helper'

# ユーザ設定管理テスト
class PreferencesControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # 登録画面の表示
  def test_new
    get :new

    assert_response :success
    assert_template 'preferences/form'
    assert_kind_of Preference, assigns(:preference)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    plan = preference_plan(:user => @current_user)
    assert_no_difference(['Preference.count']) do
      post :confirm_before_create,
           :preference => plan
    end

    assert_response :success
    assert_template 'preferences/confirm'
    assert_equal true, assigns(:preference).valid?
  end
  
  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    assert_no_difference(['Preference.count']) do
      post :confirm_before_create,
           :preference => Preference.plan(:home_layout_type => 0)
    end

    assert_equal false, assigns(:preference).valid?
    assert_response :success
    assert_template 'preferences/form'
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    post :confirm_before_create, :preference => Preference.plan, :clear => "Clear"

    assert_response :redirect
    assert_redirected_to new_preference_path
  end
  
  # 登録データの作成
  def test_create_preference
    assert_difference(['Preference.count']) do
      post :create, :preference => Preference.plan(:skype_id => "new_skype_id")
    end

    @preference = Preference.last
    assert_equal "new_skype_id", @preference.skype_id

    assert_redirected_to complete_after_create_preference_path(@preference)
  end
  
  # 登録データの作成キャンセル
  def test_create_preference_cancel
    assert_no_difference(['Preference.count']) do
      post :create, :preference => Preference.plan, :cancel => "Cancel"
    end

    assert_not_nil assigns(:preference)
    assert_template 'preferences/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_preference_fail
    assert_no_difference(['Preference.count']) do
      post :create, :preference => {:home_layout_type => 0}
    end

    assert_template 'preferences/form'
  end

  # 編集画面の表示
  def test_edit
    get :edit, :id => @current_user.preference.id

    assert_response :success
    assert_template 'preferences/form'
    assert_kind_of Preference, assigns(:preference)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    post(:confirm_before_update, :id => @current_user.preference.id,
        :preference => preference_plan(:user => @current_user))

    assert_response :success
    assert_template 'preferences/confirm'
    assert_equal true, assigns(:preference).valid?
  end
  
  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    post(:confirm_before_update, :id => @current_user.preference.id,
        :preference => Preference.plan(:home_layout_type => ""))

    assert_response :success
    assert_template 'preferences/form'
    assert_equal false, assigns(:preference).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    entry = @current_user.preference
    post(:confirm_before_update, :id => entry.id,
        :preference => Preference.plan,
        :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_preference_path(entry)
  end
  
  # 編集データの更新
  def test_update_preference
    record = @current_user.preference

    assert_no_difference(['Preference.count']) do
      put :update, :id => record.id,
          :preference => Preference.plan(:home_layout_type => Preference::HOME_LAYOUT_TYPES[:mixi])
    end

    @preference = Preference.last
    assert_equal Preference::HOME_LAYOUT_TYPES[:mixi], @preference.home_layout_type

    assert_redirected_to complete_after_update_preference_path(@preference)
  end
  
  # 編集データの作成キャンセル
  def test_update_preference_cancel
    record = @current_user.preference

    put :update, :id => record.id, :preference => Preference.plan, :cancel => "Cancel"

    assert_not_nil assigns(:preference)
    assert_template 'preferences/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_preference_fail
    record = @current_user.preference
    before_home_layout_type = record.home_layout_type

    put :update, :id => record.id, :preference => Preference.plan(:home_layout_type => "")

    assert_equal before_home_layout_type, record.home_layout_type
    assert_template 'preferences/form'
  end

  # ホームレイアウト更新
  def test_update_home_layout_type
    put(:update_home_layout_type,
        :preference => {:home_layout_type => Preference::HOME_LAYOUT_TYPES[:mixi], :user_id => @current_user.id})

    pref = @current_user.preference.reload
    assert_equal Preference::HOME_LAYOUT_TYPES[:mixi], pref.home_layout_type
    assert_redirected_to my_home_users_path
  end

  private

  # Preferenceモデルのプラン
  #
  # ==== 備考
  #
  # Preferenceが拡張機能で使用されるため、MoviePreference等をテストしたい
  # 場合はこちらを使用してください。
  def preference_plan(attributes_or_type={})
    preference_plan = Preference.plan(attributes_or_type)
    Preference.preference_associations.each do |name|
      preference_plan[name.to_s + "_attributes"] = name.to_s.classify.constantize.plan(:preference => Preference.new(preference_plan))
    end
    return preference_plan
  end
end

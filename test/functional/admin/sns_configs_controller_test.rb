require File.dirname(__FILE__) + '/../../test_helper'

# SNS設定管理テスト
class Admin::SnsConfigsControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make(:admin => true)
    login_as(@current_user)
  end

  # 一覧画面の表示
  def test_index
    get :index
    assert_response :redirect
    assert_kind_of SnsConfig, assigns(:sns_config)
    assert_redirected_to edit_admin_sns_config_path(assigns(:sns_config).id)
  end

  # 編集画面の表示
  def test_edit
    get :edit, :id => SnsConfig.make.id

    assert_response :success
    assert_template 'admin/sns_configs/form'
    assert_kind_of SnsConfig, assigns(:sns_config)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    post(:confirm_before_update, :id => SnsConfig.make.id,
        :sns_config => SnsConfig.plan)

    assert_response :success
    assert_template 'admin/sns_configs/confirm'
    assert_equal true, assigns(:sns_config).valid?
  end
  
  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail

    post(:confirm_before_update, :id => SnsConfig.make.id,
        :sns_config => SnsConfig.plan( :title => nil ))

    assert_response :success
    assert_template 'admin/sns_configs/form'
    assert_equal false, assigns(:sns_config).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    entry = SnsConfig.make
    post(:confirm_before_update, :id => entry.id,
        :sns_config => SnsConfig.plan,
        :clear => "全てクリア")

    assert_response :redirect
    assert_redirected_to edit_admin_sns_config_path(entry)
  end
  
  # 編集データの更新
  def test_update_sns_config
    sns_config = SnsConfig.make
    current_attributes = SnsConfig.plan
    updating_attributes = SnsConfig.plan(:title => "TEST_NAME",:outline => "TEST_OUTLINE",:admin_mail_address => "test@example.com")
    assert_no_difference(['SnsConfig.count']) do
      put :update, :id => sns_config.id, :sns_config => updating_attributes
    end

    sns_config.reload

    assert_redirected_to complete_after_update_admin_sns_config_path(sns_config.id)
    assert "修正完了いたしました", assigns(:message)

    expected_attributes = current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, sns_config.send(attribute)
    end
  end
  
  # 編集データの作成キャンセル
  def test_update_sns_config_cancel
    record = SnsConfig.make

    put :update, :id => record.id, :sns_config => SnsConfig.plan, :cancel => "入力画面へ戻る"

    assert_not_nil assigns(:sns_config)
    assert_template 'admin/sns_configs/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_sns_config_fail
    new_record = SnsConfig.make
    expected_record = Marshal.load(Marshal.dump(new_record))
    put :update, :id => new_record.id, :sns_config => SnsConfig.plan( :title => nil )

    new_record.reload

    expected_record.attributes.each do |attribute, value|
      assert_equal value, new_record.send(attribute)
    end

    assert expected_record.eql?(new_record)
    assert_template 'admin/sns_configs/form'
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class SnsLinkagesControllerTest < ActionController::TestCase
  def setup
   @current_user = User.make
   login_as(@current_user)
  end

  # SNS連携サイト設定画面
  def test_new
    get :new

    assert_not_nil assigns(:sns_linkages)
    assert_template "new"
  end

  # SNS連携キー設定
  def test_create
    plan = SnsLinkage.plan
    assert_difference('SnsLinkage.count', 1) do
      post :create, :sns_linkage => plan
    end

    l = SnsLinkage.last
    assert_equal plan[:key], l.key
    assert_equal @current_user.id, l.user_id
    assert_redirected_to new_sns_linkage_path
  end

  # SNS連携キー設定
  def test_create_fail
    plan = SnsLinkage.plan(:key => "")
    assert_difference('SnsLinkage.count', 0) do
      post :create, :sns_linkage => plan
    end

    assert_redirected_to new_sns_linkage_path
  end

  # SNS連携キー発行
  def test_publish_link_key
    before = @current_user.sns_link_key
    put :publish_link_key

    @current_user.reload
    assert_not_equal before, @current_user.sns_link_key
    assert_redirected_to new_sns_linkage_path
  end

  # SNS連携キー発行（リダイレクト）
  def test_publish_link_key_redirect
    put :publish_link_key, :unpublish => "Unpublish"

    assert_redirected_to unpublish_link_key_sns_linkages_path
  end

  # SNS連携キー発行停止
  def test_unpublish_link_key
    get :unpublish_link_key

    @current_user.reload
    assert_nil @current_user.sns_link_key
    assert_redirected_to new_sns_linkage_path
  end

  # SNS連携キー削除
  def test_destroy
    sl = SnsLinkage.make
    sl.user = @current_user
    sl.save!

    assert_difference('SnsLinkage.count', -1) do
      delete :destroy, :id => sl.id
    end

    assert_redirected_to new_sns_linkage_path
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class RankingsControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # 最新ランキングの表示
  def test_latest_ranking
    get :index

    assert_template "index"
    assert_response :success
  end

  # 総合ランキングの表示
  def test_total_ranking
    get :index, :type => "total"

    assert_template "index"
    assert_response :success
  end

  # 非ログイン状態だと、ランキング機能にアクセスできない
  def test_access_deny_without_login
    logout

    assert_raise Acl9::AccessDenied do
      get :index
    end
  end

  # SNS設定で、ランキング表示がオフになっている場合はroot_urlへリダイレクトさせる
  def test_redirect_to_root_when_ranking_display_flg_false
    SnsConfig.first.update_attributes(:ranking_display_flg => false)

    get :index

    assert_response :redirect
    assert_redirected_to root_url
  end
end

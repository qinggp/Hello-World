require File.dirname(__FILE__) + '/../test_helper'

# 静的ページ管理テスト
class PagesControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
  end

  # 静的ページ表示
  def test_show
    page = Page.make

    get :show, :id => page.page_id

    assert_response :success
    assert_template "show"
  end
end

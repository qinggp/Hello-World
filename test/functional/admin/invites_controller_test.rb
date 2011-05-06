require File.dirname(__FILE__) + '/../../test_helper'

# 招待ユーザ管理テスト
class Admin::InvitesControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make(:admin => true)
    login_as(@current_user)
  end

  # 一覧画面の表示
  def test_index
    get :index

    assert_response :success
    assert_template 'admin/invites/index'
    assert_not_nil assigns(:invites)
  end

  # 検索
  def test_search
    invite = Invite.make(:email => "search_hit@invite.com")

    get :index, :invite => {:email => invite.email}

    assert_response :success
    assert_template 'admin/invites/index'
    assert_not_nil assigns(:invites)
  end
end

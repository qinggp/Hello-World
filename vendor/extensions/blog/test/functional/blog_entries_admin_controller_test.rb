require File.dirname(__FILE__) + '/../test_helper'

class BlogEntriesAdminControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
  end

  # ブログ管理画面表示
  def test_index
    get :index, :user_id => @current_user.id

    assert_response :success
    assert_not_nil assigns(:blog_entries)
    assert_not_nil assigns(:user)
  end

  # ブログ記事属性一括修正
  def test_update_checked
    checked_ids = []
    2.times{ checked_ids << BlogEntry.make.id.to_s }

    post(:update_checked, :user_id => @current_user.id,
         :checked_ids => checked_ids,
         :blog_entry => {:comment_restraint => "",
            :visibility => BlogPreference::VISIBILITIES[:unpubliced]})

    checked_ids.each do |id|
      assert_equal BlogPreference::VISIBILITIES[:unpubliced], BlogEntry.find(id).visibility
    end
    assert_response :redirect
  end

  # ブログ記事属性一括修正
  def test_destroy_checked
    checked_ids = []
    2.times{ checked_ids << BlogEntry.make.id.to_s }

    post(:destroy_checked, :user_id => @current_user.id,
         :checked_ids => checked_ids)

    checked_ids.each do |id|
      assert_nil BlogEntry.find_by_id(id)
    end
    assert_response :redirect
  end

  # ブログ記事全選択
  def test_all_checked
    set_mobile_user_agent

    post(:all_checked, :user_id => @current_user.id)

    assert_response :success
    assert_template "index"
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class TracksControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # あしあとトップページのテスト
  def test_index
    10.times do
      visitor = User.make
      2.times do
        track_make(:user_id => @current_user.id, :visitor_id => visitor.id)
      end
    end

    get :index

    assert_equal 20, assigns(:total_access)
    assert_equal 10, assigns(:tracks).length

    assert_response :success
    assert_template "tracks/index"
  end

  # あしあとトップページで、表示件数が多いときのテスト
  # 50人が合計100件のあしあとをつけている状況
  def test_index_too_many
    50.times do
      visitor = User.make
      2.times do
        track_make(:user_id => @current_user.id, :visitor_id => visitor.id)
      end
    end

    get :index

    assert_equal 100, assigns(:total_access)
    assert_equal 30, assigns(:tracks).length

    assert_response :success
    assert_template "tracks/index"
  end

  # キリ番ごとの表示
  def test_search_with_split_number
    total_count = 53
    split_number = 10
    visitor = User.make

    total_count.times do
      track_make(:user_id => @current_user.id, :visitor_id => visitor.id)
    end

    get :search, :split_number => split_number

    assert_equal total_count / split_number, assigns(:tracks).length

    assert_response :success
    assert_template "tracks/index"
  end

  # 特定の番号の表示
  def test_search_with_pspecific_number
    total_count = 10
    specific_numer = 3
    visitor = User.make
    specific_track = nil

    total_count.times do |n|
      if (n + 1) == specific_numer
        specific_track =  track_make(:user_id => @current_user.id, :visitor_id => visitor.id)
      else
        track_make(:user_id => @current_user.id, :visitor_id => visitor.id)
      end
    end

    get :search, :specific_number => specific_numer

    assert_equal specific_track.id, assigns(:tracks).first.id

    assert_response :success
    assert_template "tracks/index"
  end

  # あしあとの中に既に存在しないユーザが含まれているとき
  def test_search_when_visitor_is_already_destroyed
    visitor = User.make
    track_make(:user_id => @current_user.id, :visitor_id => visitor.id)
    visitor.destroy

    get :search

    # 合計のあしあとは変わらない
    assert 1, assigns(:totla_access)

    assert_response :success
    assert_template "tracks/index"
  end

  # ログインしていないと見れない
  def test_access_without_login
    logout

    assert_raise Acl9::AccessDenied do
      get :index
    end
  end
end

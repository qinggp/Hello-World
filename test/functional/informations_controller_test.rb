require File.dirname(__FILE__) + '/../test_helper'

# お知らせ機能テスト
class InformationsControllerTest < ActionController::TestCase
  def setup
    @current_user = User.make
    login_as(@current_user)
  end

  #お知らせ一覧表示
  def test_index
    hit = Information.make
    hit_expire_date_old = Information.make(:expire_date => 2.years.ago)
    not_hit_external_only = Information.make(:public_range => Information::PUBLIC_RANGES[:external_only])

    get :index

    informations = assigns(:informations)
    assert_equal true, informations.any?{|info| info.id == hit.id }
    assert_equal true, informations.any?{|info| info.id == hit_expire_date_old.id }
    assert_equal false, informations.any?{|info| info.id == not_hit_external_only }
  end

  #お知らせ一覧表示
  def test_index_anonymous_user
    logout

    hit = Information.make(:public_range => Information::PUBLIC_RANGES[:external_only])
    not_hit = Information.make(:expire_date => 2.years.ago)
    not_hit_sns_only = Information.make(:public_range => Information::PUBLIC_RANGES[:sns_only])

    get :index

    informations = assigns(:informations)
    assert_equal true, informations.any?{|info| info.id == hit.id }
    assert_equal false, informations.any?{|info| info.id == not_hit.id }
    assert_equal false, informations.any?{|info| info.id == not_hit_sns_only }
    assert_template "index"
  end

  #重要なお知らせ一覧表示
  def test_index_for_important
    hit = Information.make(:display_type => Information::DISPLAY_TYPES[:important])
    not_hit = Information.make(:display_type => Information::DISPLAY_TYPES[:fixed])
    not_hit_expire_date_old =
      Information.make(:expire_date => 2.years.ago,
                       :display_type => Information::DISPLAY_TYPES[:important])
    

    get :index_for_important

    informations = assigns(:informations)
    assert_equal true, informations.any?{|info| info.id == hit.id }
    assert_equal false, informations.any?{|info| info.id == not_hit_expire_date_old.id }
    assert_equal false, informations.any?{|info| info.id == not_hit.id }
    assert_template "index"
  end

  # お知らせ詳細表示
  def test_show
    logout

    record =Information.make(:public_range => Information::PUBLIC_RANGES[:external_only])

    get :show, :id => record.id

    assert_template "show"
  end

  # お知らせ詳細表示（指定したお知らせがない）
  def test_show_not_found
    logout

    record =Information.make(:public_range => Information::PUBLIC_RANGES[:external_only])
    id = record.id
    record.destroy

    get :show, :id => id

    assert_redirected_to informations_path
  end
end

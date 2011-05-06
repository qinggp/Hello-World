require File.dirname(__FILE__) + '/../../test_helper'

class Admin::AnnouncementsControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make(:admin => true)
    login_as(@current_user)
  end

  #お知らせ一覧画面（ログイン状態）
  def test_index
    set_informations()
    get :index
    assert_response :success
    assert_equal 80, Information.count
  end

  # お知らせ一覧画面で表示件数を指定したときのページネーションの結果が正しいことを確認する
  def test_index_received_per_page
    set_informations

    get :index,:per_page_important => 10,:per_page_new => 5

    expected_total_pages_important = ((Information.find(:all,:conditions => ["display_type = ?", Information::DISPLAY_TYPES[:important]]).count)/10.to_f).ceil
    expected_total_pages_new = ((Information.find(:all,:conditions => ["display_type = ? OR display_type = ?", Information::DISPLAY_TYPES[:new], Information::DISPLAY_TYPES[:private]]).count)/5.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages_important, assigns(:announcements_important).total_pages
    assert_equal expected_total_pages_new, assigns(:announcements_new).total_pages
    assert_equal 1, assigns(:announcements_important).current_page
    assert_equal 1, assigns(:announcements_new).current_page
  end

  # お知らせ一覧画面でページ数を指定したときのページネーションの結果が正しいことを確認する
  def test_index_received_page
    set_informations

    get :index,:select_page_important => 2,:select_page_new => 3

    default_per_page = 5

    expected_total_pages_important = ((Information.find(:all,:conditions => ["display_type = ?", Information::DISPLAY_TYPES[:important]]).count)/default_per_page.to_f).ceil
    expected_total_pages_new = ((Information.find(:all,:conditions => ["display_type = ? OR display_type = ?", Information::DISPLAY_TYPES[:new], Information::DISPLAY_TYPES[:private]]).count)/default_per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages_important, assigns(:announcements_important).total_pages
    assert_equal expected_total_pages_new, assigns(:announcements_new).total_pages

    assert_equal 2, assigns(:announcements_important).current_page
    assert_equal 3, assigns(:announcements_new).current_page
    assert_equal default_per_page, assigns(:announcements_important).size
    assert_equal default_per_page, assigns(:announcements_new).size
  end

  # お知らせ一覧画面で表示件数とページ数を指定したときの
  # ページネーションの結果が正しいことを確認する
  def test_index_received_per_page_
    set_informations

    page = 2
    per_page = 10

    get :index,:per_page_important => per_page,:per_page_new => per_page,:select_page_important => page,:select_page_new => page

    expected_total_pages_important = ((Information.find(:all,:conditions => ["display_type = ?", Information::DISPLAY_TYPES[:important]]).count)/per_page.to_f).ceil
    expected_total_pages_new = ((Information.find(:all,:conditions => ["display_type = ? OR display_type = ?", Information::DISPLAY_TYPES[:new], Information::DISPLAY_TYPES[:private]]).count)/per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages_important,assigns(:announcements_important).total_pages
    assert_equal expected_total_pages_new,assigns(:announcements_new).total_pages
    assert_equal page, assigns(:announcements_important).current_page
    assert_equal page, assigns(:announcements_new).current_page
    assert_equal per_page, assigns(:announcements_important).size
    assert_equal per_page, assigns(:announcements_new).size
  end

  # お知らせ新規作成画面
  def test_new
    get :new

    assert_response :success
  end

  # お知らせ編集画面
  def test_edit
    set_informations(1)
    get :edit, :id => 1

    assert_response :success
  end

  # お知らせ新規作成「全てクリア」ボタン
  def test_confirm_before_create_clear
    attributes = Information.plan()
    assert_no_difference "Information.count" do
      post :confirm_before_create,
           :information => attributes,
           :clear => '全てクリア'
    end
    assert_redirected_to :controller => 'admin/announcements', :action => 'new'
  end

  # お知らせ編集「全てクリア」ボタン
  def test_confirm_before_update_clear
    information = information(:music)
    updating_attributes = {
      :id => information.id,
      :title => information.comment,
      :display_link => information.display_link,
      :click_count => information.click_count
    }
    assert_no_difference "Information.count" do
      post :confirm_before_update,
           :id => information.id,
           :information => updating_attributes,
           :clear => '全てクリア'
    end
    assert_redirected_ro :controller => 'admin/announcements', :action => 'edit'
  end

  # お知らせ新規作成エラー
  def test_confirm_before_create_error
    attributes = Information.plan(:title => nil,
                             :display_link => nil,
                             :expire_date => nil)
    assert_no_difference "Information.count" do
      post :confirm_before_create,
           :information => attributes
    end
    assert_equal false, assigns(:announcement).valid?
    assert_template :"form"
  end

  # お知らせ編集エラー
  def test_confirm_before_update_clear
    information = information(:test1005)
    updating_attributes = {
      :id => information.id,
      :title => nil,
      :display_link => nil,
      :expire_date => nil}
    assert_no_difference "Information.count" do
      post :confirm_before_update,
           :id => information.id,
           :information => updating_attributes
    end
    assert_equal false, assigns(:announcement).valid?
    assert_template :"form"

  end

  # お知らせ新規作成確認画面
  def test_confirm_before_create
    attributes =  Information.plan(:content => "本文")

    assert_no_difference "Information.count" do
      post :confirm_before_create,
           :information => attributes
    end

    assert_response :success
    assert_template :"confirm"

    attributes.each do |attribute, value|
      assert_equal value, assigns(:announcement).send(attribute)
    end
  end

  # お知らせ編集確認画面
  def test_confirm_before_update
    information = set_informations(1)

    updating_attributes = {:title => "お知らせテストタイトル",
                           :content => "お知らせテストコンテンツ",
                           :expire_date => Time.gm(2009,"oct",15,20,21)
    }

    current_attributes = Information.plan

    assert_no_difference "Information.count" do
      post :confirm_before_update,
           :id => information.id,
           :information => updating_attributes
    end

    assert_response :success
    assert_template :"confirm"

    expected_attributes =
      current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, assigns(:announcement).send(attribute)
    end
  end

  # お知らせ作成後、お知らせ作成完了画面
  def test_create
    attributes = Information.plan()

    assert_difference "Information.count" do
      post :create, :information => attributes
    end

    announcement = assigns(:announcement)
    assert_response :redirect
    assert_redirected_to complete_after_create_admin_announcement_path(:id => announcement.id)
    assert "作成完了いたしました", assigns(:message)

    attributes.each do |attribute, value|
      assert_equal value, announcement.send(attribute)
    end
  end



  # お知らせ編集後、お知らせ編集完了画面
  def test_update
    information = set_informations()

    current_attributes = Information.plan
    updating_attributes =
      Information.plan(:title => "お知らせテストタイトル",
                         :content => "お知らせテストコンテンツ",
                         :expire_date => Date.yesterday)

    assert_no_difference "Information.count" do
      put :update, :id => information.id, :information => updating_attributes
    end

    information.reload
    assert_response :redirect
    assert_redirected_to complete_after_update_admin_announcement_path(information.id)
    assert "修正完了いたしました", assigns(:message)

    expected_attributes = current_attributes.update(updating_attributes)
    expected_attributes.each do |attribute, value|
      assert_equal value, information.send(attribute)
    end
  end

  # お知らせ作成「入力画面へ戻る」ボタン
  def test_create_cancel
    information = information(:test1005)
    attributes = Information.plan(:title => information.title,
                             :display_link => information.display_link)

    assert_no_difference "Information.count" do
      post :create, :information => attributes, :cancel => '入力画面へ戻る'
    end
    assert_template :"form"
  end

  # お知らせ編集「入力画面へ戻る」ボタン
  def test_update_cancel
    information = information(:test1005)
    updating_attributes = {
      :title => "テストタイトル",
      :display_link => information.display_link
    }
    assert_no_difference "Information.count" do
      put :update,
          :id => information.id,
          :information => updating_attributes,
          :cancel => '入力画面へ戻る'
    end
    information.reload

    assert_template :"form"
  end

  # お知らせ作成完了画面
  def test_complete_after_create
    information = set_informations(1)

    get :complete_after_create, :id => information.id

    assert_response :success
    assert_template "share/complete"
  end

  # お知らせ編集完了画面
  def test_complete_after_update
    information = set_informations(1)

    get :complete_after_update, :id => information.id

    assert_response :success
    assert_template "share/complete"
  end

  private

  def set_informations(num = 20)
    Information.destroy_all

    1.upto(num) do |index|
      attributes = {
        :id => index.to_s,
        :title => "テストお知らせ #{index}",
        :content => "テストお知らせ #{index}",
        :expire_date => Time.now.to_s,
        :display_type => Information::DISPLAY_TYPES[:new],
        :public_range => Information::PUBLIC_RANGES[:sns_only],
        :display_link => Information::DISPLAY_LINKS[:link],
      }
      Information.make(attributes)
    end

    1.upto(num) do |index|
      attributes = {
        :id => (index + num).to_s,
        :title => "テストお知らせ #{index + num}",
        :content => "テストお知らせ #{index + num}",
        :expire_date => Time.now.to_s,
        :display_type => Information::DISPLAY_TYPES[:fixed],
        :public_range => Information::PUBLIC_RANGES[:published_externally],
        :display_link => Information::DISPLAY_LINKS[:no_link],
      }
      Information.make(attributes)
    end

    1.upto(num) do |index|
      attributes = {
        :id => (index + num * 2).to_s,
        :title => "テストお知らせ #{index + num * 2}",
        :content => "テストお知らせ #{index + num * 2}",
        :expire_date => Time.now.to_s,
        :display_type => Information::DISPLAY_TYPES[:important],
        :public_range => Information::PUBLIC_RANGES[:external_only],
        :display_link => Information::DISPLAY_LINKS[:link],
      }
      Information.make(attributes)
    end

    1.upto(num) do |index|
      attributes = {
        :id => (index + num * 3).to_s,
        :title => "テストお知らせ #{index + num * 3}",
        :content => "テストお知らせ #{index + num * 3}",
        :expire_date => Time.now.to_s,
        :display_type => Information::DISPLAY_TYPES[:important],
        :public_range => Information::PUBLIC_RANGES[:external_only],
        :display_link => Information::DISPLAY_LINKS[:link],
      }
      Information.make(attributes)
    end
    return Information.find(1)
  end
end

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ContentsControllerTest < ActionController::TestCase

  def setup
    @current_user ||= User.make(:admin => true)
    login_as(@current_user)
  end


  # 書き込み管理機能のテスト
  # 正しいアクションに移動しているか
  def test_search_top

    if Mars::Extension.instance.extension_enabled?(:blog)
      # ブログコメント書き込み管理
      get :search_top, :genre => "blog_comments", :type => "write", :search => true
      assert_redirected_to wrote_administration_blog_comments_admin_blog_entries_path(:type => "write")

      # ブログ書き込み管理
      get :search_top, :genre => "blog_entries", :type => "write", :search => true
      assert_redirected_to wrote_administration_blog_entries_admin_blog_entries_path(:type => "write")

      # ブログファイル管理
      get :search_top, :genre => "blog_entries", :type => "file", :search => true
      assert_redirected_to wrote_administration_blog_entries_admin_blog_entries_path(:type => "file")
    end

    if Mars::Extension.instance.extension_enabled?(:community)
      # コミュニティ書き込み管理
      get :search_top, :genre => "communities", :type => "write", :search => true
      assert_redirected_to wrote_administration_communities_admin_communities_path(:type => "write")

      # コミュニティファイル管理
      get :search_top, :genre => "communities", :type => "file", :search => true
      assert_redirected_to wrote_administration_communities_admin_communities_path(:type => "file")

      # コミュニティイベント書き込み管理
      get :search_top, :genre => "events", :type => "write", :search => true
      assert_redirected_to wrote_administration_events_admin_communities_path(:type => "write")

      # コミュニティイベントファイル管理
      get :search_top, :genre => "events", :type => "file", :search => true
      assert_redirected_to wrote_administration_events_admin_communities_path(:type => "file")

      # コミュニティトピック書き込み管理
      get :search_top, :genre => "topics", :type => "write", :search => true
      assert_redirected_to wrote_administration_topics_admin_communities_path(:type => "write")

      # コミュニティトピック管理
      get :search_top, :genre => "topics", :type => "file", :search => true
      assert_redirected_to wrote_administration_topics_admin_communities_path(:type => "file")
    end

    # プロフィール画像管理
    get :search_top, :genre => "face_photo", :type => "file", :search => true
    assert_redirected_to wrote_administration_face_photo_admin_users_path(:type => "file")


  end


end

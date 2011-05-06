require File.dirname(__FILE__) + '/../../test_helper'

# ブログ書き込み管理テスト
class Admin::BlogEntriesControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make(:admin => true)
    login_as(@current_user)
  end

  # ブログコメント書き込み管理のテスト
  def test_wrote_administration_blog_comment_write
    blog_entry = BlogEntry.make
    10.times do
      BlogComment.make(:blog_entry => blog_entry)
    end
    page = 2
    per_page = 5

    blog_comments = BlogComment.find(:all)

    # 条件指定なし
    get :wrote_administration_blog_comments

    assert_response :success
    assert_template 'admin/blog_entries/wrote_administration_blog_comments_write'
    assert_not_nil assigns(:blog_comments)

    # ページ指定
    get :wrote_administration_blog_comments, :per_page => per_page

    expected_total_pages = (blog_comments.count / per_page.to_f).ceil
    assert_response :success
    assert_equal expected_total_pages, assigns(:blog_comments).total_pages
    assert_equal 1, assigns(:blog_comments).current_page
    assert_equal per_page, assigns(:blog_comments).size
    
    # 表示件数指定
    get :wrote_administration_blog_comments, :page => page

    assert_response :success
    assert_equal page, assigns(:blog_comments).current_page

    # 表示件数、ページ指定
    get :wrote_administration_blog_comments, :page => page, :per_page => per_page
    expected_total_pages = (blog_comments.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:blog_comments).total_pages
    assert_equal page, assigns(:blog_comments).current_page
    assert_equal per_page, assigns(:blog_comments).size



  end

  # ブログ書き込みのテスト
  def test_wrote_administration_blog_entry_write
    10.times do
      BlogEntry.make
    end
    per_page = 5
    page = 2
    blog_entries = BlogEntry.find(:all)
    
    # 条件指定なし
    get :wrote_administration_blog_entries, :type => "write"

    assert_response :success
    assert_template 'admin/blog_entries/wrote_administration_blog_entries_write'
    assert_not_nil assigns(:blog_entries)

    # 表示件数指定
    get :wrote_administration_blog_entries, :per_page => per_page, :type => "write"

    expected_total_pages = (blog_entries.count / per_page.to_f).ceil
    assert_response :success
    assert_equal expected_total_pages, assigns(:blog_entries).total_pages
    assert_equal 1, assigns(:blog_entries).current_page
    assert_equal per_page, assigns(:blog_entries).size

    # ページ指定
    get :wrote_administration_blog_entries, :page => page, :type => "write"

    assert_response :success
    assert_equal page, assigns(:blog_entries).current_page

    # 表示件数、ページ指定
    get :wrote_administration_blog_entries, :page => page, :per_page => per_page, :type => "write"
    expected_total_pages = (blog_entries.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:blog_entries).total_pages
    assert_equal page, assigns(:blog_entries).current_page
    assert_equal per_page, assigns(:blog_entries).size

  end

  # ブログファイル管理
  def test_wrote_administration_blog_entry_file
    10.times do
      blog_entry = BlogEntry.make
      BlogAttachment.make(:position => 1, :blog_entry => blog_entry, :image => upload("#{RAILS_ROOT}/public/images/rails.png"))
    end
    per_page = 5
    page = 2
    blog_attachments = BlogAttachment.find(:all)

    # 条件なし
    get :wrote_administration_blog_entries, :type => "file"

    assert_response :success
    assert_template 'admin/blog_entries/wrote_administration_blog_entries_file'
    assert_not_nil assigns(:blog_attachments)

    # 表示件数指定
    get :wrote_administration_blog_entries, :per_page => per_page, :type => "file"

    expected_total_pages = (blog_attachments.count / per_page.to_f).ceil
    assert_response :success
    assert_equal expected_total_pages, assigns(:blog_attachments).total_pages
    assert_equal 1, assigns(:blog_attachments).current_page
    assert_equal per_page, assigns(:blog_attachments).size

    # ページ指定
    get :wrote_administration_blog_entries, :page => page, :type => "file"

    assert_response :success
    assert_equal page, assigns(:blog_attachments).current_page

    # 表示件数、ページ指定
    get :wrote_administration_blog_entries, :page => page, :per_page => per_page, :type => "file"
    expected_total_pages = (blog_attachments.count / per_page.to_f).ceil

    assert_response :success
    assert_equal expected_total_pages, assigns(:blog_attachments).total_pages
    assert_equal page, assigns(:blog_attachments).current_page
    assert_equal per_page, assigns(:blog_attachments).size
  end

  # ブログファイルの削除
  def test_admin_blog_attachment_destroy
    blog_entry = BlogEntry.make
    blog_attachment = BlogAttachment.make(:position => 1, :blog_entry => blog_entry, :image => upload("#{RAILS_ROOT}/public/images/rails.png"))

    assert_difference('BlogAttachment.count', -1) do
      delete :admin_blog_attachment_destroy, :id => blog_attachment.id
    end
    assert_redirected_to wrote_administration_blog_entries_admin_blog_entries_path(:type => "file")
  end

end

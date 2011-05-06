require File.dirname(__FILE__) + '/../test_helper'

class BlogEntryTest < ActiveSupport::TestCase

  def setup
    @current_user = User.make
  end

  # 記事の可視性チェック
  def test_visible
    blog = BlogEntry.make
    blog_user = blog.user
    blog_user.preference.blog_preference =
      BlogPreference.make(:visibility => BlogPreference::VISIBILITIES[:publiced])

    blog.visibility = BlogPreference::VISIBILITIES[:publiced]
    assert_equal true, blog.visible?

    blog.visibility = BlogPreference::VISIBILITIES[:member_only]
    assert_equal false, blog.visible?
    assert_equal true, blog.visible?(@current_user)

    blog.visibility = BlogPreference::VISIBILITIES[:friend_only]
    assert_equal false, blog.visible?(@current_user)

    @current_user.friend!(blog_user)
    assert_equal true, blog.visible?(@current_user)

    blog.visibility = BlogPreference::VISIBILITIES[:unpubliced]
    assert_equal false, blog.visible?(@current_user)

    blog.user = @current_user
    assert_equal true, blog.visible?(@current_user)
  end

  # 記事へのコメント可能性チェック
  def test_commentable
    blog = BlogEntry.make
    blog_user = blog.user

    blog.comment_restraint = BlogPreference::VISIBILITIES[:publiced]
    assert_equal true, blog.commentable?

    blog.comment_restraint = BlogPreference::VISIBILITIES[:member_only]
    assert_equal false, blog.commentable?
    assert_equal true, blog.commentable?(@current_user)

    blog.comment_restraint = BlogPreference::VISIBILITIES[:friend_only]
    assert_equal false, blog.commentable?(@current_user)

    @current_user.friend!(blog_user)
    assert_equal true, blog.commentable?(@current_user)

    blog.user = @current_user
    assert_equal true, blog.commentable?(@current_user)

    blog.comment_restraint = BlogPreference::VISIBILITIES[:unpubliced]
    assert_equal false, blog.commentable?(@current_user)
  end

  # 匿名ユーザ閲覧可能性チェック
  def test_viewable
    blog = BlogEntry.make
    blog_user = blog.user
    blog_user.preference.blog_preference =
      BlogPreference.make(:visibility => BlogPreference::VISIBILITIES[:publiced])

    assert_equal true, blog.anonymous_viewable?
    assert_equal true, blog.member_viewable?
    assert_equal true, blog.friend_viewable?

    blog.visibility = BlogPreference::VISIBILITIES[:member_only]

    assert_equal false, blog.anonymous_viewable?
    assert_equal true, blog.member_viewable?
    assert_equal true, blog.friend_viewable?

    blog.visibility = BlogPreference::VISIBILITIES[:friend_only]

    assert_equal false, blog.anonymous_viewable?
    assert_equal false, blog.member_viewable?
    assert_equal true, blog.friend_viewable?

    blog.visibility = BlogPreference::VISIBILITIES[:unpubliced]

    assert_equal false, blog.anonymous_viewable?
    assert_equal false, blog.member_viewable?
    assert_equal false, blog.friend_viewable?
  end

  # ブログ公開範囲、コメント制限を指定された区分値に変更されるか
  def test_visibility_narrow_down
    publiced_id = blog_entry_make(:visibility => BlogPreference::VISIBILITIES[:publiced]).id
    member_only_id = blog_entry_make(:visibility => BlogPreference::VISIBILITIES[:member_only]).id
    friend_only_id = blog_entry_make(:visibility => BlogPreference::VISIBILITIES[:friend_only]).id
    other_user_id = BlogEntry.make(:visibility => BlogPreference::VISIBILITIES[:publiced]).id

    BlogEntry.visibility_narrow_down(@current_user, BlogPreference::VISIBILITIES[:member_only])

    assert_equal BlogPreference::VISIBILITIES[:member_only], BlogEntry.find(publiced_id).visibility
    assert_equal BlogPreference::VISIBILITIES[:member_only], BlogEntry.find(member_only_id).visibility
    assert_equal BlogPreference::VISIBILITIES[:friend_only], BlogEntry.find(friend_only_id).visibility
    assert_equal true, BlogEntry.find(other_user_id).visibility_publiced?

    publiced_id = blog_entry_make(:comment_restraint => BlogPreference::VISIBILITIES[:publiced]).id
    member_only_id = blog_entry_make(:comment_restraint => BlogPreference::VISIBILITIES[:member_only]).id
    friend_only_id = blog_entry_make(:comment_restraint => BlogPreference::VISIBILITIES[:friend_only]).id

    BlogEntry.visibility_narrow_down(@current_user, BlogPreference::VISIBILITIES[:member_only])

    assert_equal BlogPreference::VISIBILITIES[:member_only], BlogEntry.find(publiced_id).comment_restraint
    assert_equal BlogPreference::VISIBILITIES[:member_only], BlogEntry.find(member_only_id).comment_restraint
    assert_equal BlogPreference::VISIBILITIES[:friend_only], BlogEntry.find(friend_only_id).comment_restraint
  end

  # 指定ユーザ閲覧可能ブログ記事一覧取得テスト
  def test_by_visible
    other_user  = User.make
    publiced    = BlogEntry.make(:visibility => BlogPreference::VISIBILITIES[:publiced],
                                 :user => other_user)
    member_only = BlogEntry.make(:visibility => BlogPreference::VISIBILITIES[:member_only],
                                 :user => other_user)
    friend_only = BlogEntry.make(:visibility => BlogPreference::VISIBILITIES[:friend_only],
                                 :user => other_user)
    unpubliced  = BlogEntry.make(:visibility => BlogPreference::VISIBILITIES[:unpubliced],
                                 :user => other_user)

    # 無名ユーザ検索
    records = BlogEntry.by_visible(nil)
    assert_not_nil records.detect{|rec| rec.id == publiced.id}
    assert_nil records.detect{|rec| rec.id == member_only.id}
    assert_nil records.detect{|rec| rec.id == friend_only.id}
    assert_nil records.detect{|rec| rec.id == unpubliced.id}

    # ログインユーザ検索
    records = BlogEntry.by_visible(@current_user)
    assert_not_nil records.detect{|rec| rec.id == publiced.id}
    assert_not_nil records.detect{|rec| rec.id == member_only.id}
    assert_nil records.detect{|rec| rec.id == friend_only.id}
    assert_nil records.detect{|rec| rec.id == unpubliced.id}

    # トモダチのブログ記事引っかかるか
    friend_user  = User.make
    @current_user = User.make
    @current_user.friend!(friend_user)
    friend_only = BlogEntry.make(:visibility => BlogPreference::VISIBILITIES[:friend_only],
                                 :user => friend_user)
    unpubliced  = BlogEntry.make(:visibility => BlogPreference::VISIBILITIES[:unpubliced],
                                 :user => friend_user)

    records = BlogEntry.by_visible(@current_user)
    assert_not_nil records.detect{|rec| rec.id == friend_only.id}
    assert_nil records.detect{|rec| rec.id == unpubliced.id}

    # 自分の記事が非公開以外ヒットするか
    publiced    = blog_entry_make(:visibility => BlogPreference::VISIBILITIES[:publiced])
    member_only = blog_entry_make(:visibility => BlogPreference::VISIBILITIES[:member_only])
    friend_only = blog_entry_make(:visibility => BlogPreference::VISIBILITIES[:friend_only])
    unpubliced  = blog_entry_make(:visibility => BlogPreference::VISIBILITIES[:unpubliced])
    
    records = BlogEntry.by_visible(@current_user)
    assert_not_nil records.detect{|rec| rec.id == publiced.id}
    assert_not_nil records.detect{|rec| rec.id == member_only.id}
    assert_not_nil records.detect{|rec| rec.id == friend_only.id}
    assert_not_nil records.detect{|rec| rec.id == unpubliced.id}

    records = BlogEntry.by_visible(@current_user, false)
    assert_nil records.detect{|rec| rec.id == unpubliced.id}
  end

  # ブログ記事のコメントのカウンタキャッシュ検証
  def test_blog_comment_counter
    blog = blog_entry_make
    BlogComment.make(:blog_entry_id => blog.id)
    assert_equal 1, blog.blog_comments.count
  end

  # 外部RSSのエントリをブログエントリリストにマージ
  def test_merge_imported_entries_by_rss
    entry = blog_entry_make
    entries = BlogEntry.
      merge_imported_entries_by_rss(File.join(RAILS_ROOT, "test/fixtures/files/test.rss"),[entry])
    assert_equal true, entries.size > 1

    entries = BlogEntry.
      merge_imported_entries_by_rss(File.join(RAILS_ROOT, "test/fixtures/files/test.rdf"),[entry])
    assert_equal true, entries.size > 1
    assert_nil entries.last.id
    %w(imported_by_rss url_to_article rss_title rss_url).each do |column|
      assert_not_nil entries.last.send(column)
    end
  end

  # 外部RSSのエントリをブログエントリリストにマージ（atom）
  def test_merge_imported_entries_by_rss_for_atom
    entry = BlogEntry.
      merge_imported_entries_by_rss(File.join(RAILS_ROOT, "test/fixtures/files/test.atom"), []).first

    %w(imported_by_rss url_to_article rss_title rss_url created_at).each do |column|
      assert_equal false, entry.send(column).blank?
    end
    assert_equal "本文", entry.body

    entry = BlogEntry.
      merge_imported_entries_by_rss(File.join(RAILS_ROOT, "test/fixtures/files/test_ver_3_0.atom"), []).first
    %w(imported_by_rss url_to_article rss_title rss_url created_at).each do |column|
      assert_equal false, entry.send(column).blank?
    end
    assert_equal "Mars テスト", entry.body
  end

  # ユーザ削除
  def test_user_destroy
    user = User.make
    entry = BlogEntry.make
    entry.blog_comments << BlogComment.make
    entry.blog_attachments << BlogAttachment.make
    user.blog_categories << BlogCategory.make
    BlogComment.make(:user => user)
    user.blog_entries << entry
    user.save!

    assert_not_nil BlogEntry.find_by_user_id(user.id)
    assert_not_nil BlogComment.find_by_blog_entry_id(entry.id)
    assert_not_nil BlogAttachment.find_by_blog_entry_id(entry.id)
    assert_not_nil BlogCategory.find_by_user_id(user.id)
    assert_not_nil BlogComment.find_by_user_id(user.id)

    user.destroy

    assert_nil BlogEntry.find_by_user_id(user.id)
    assert_nil BlogComment.find_by_blog_entry_id(entry.id)
    assert_nil BlogAttachment.find_by_blog_entry_id(entry.id)
    assert_nil BlogCategory.find_by_user_id(user.id)
    assert_nil BlogComment.find_by_user_id(user.id)
  end

  private
  def blog_entry_make(attributes={})
    return BlogEntry.make(attributes.merge(:user => @current_user))
  end
end

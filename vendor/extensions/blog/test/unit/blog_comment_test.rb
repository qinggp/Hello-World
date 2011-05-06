require File.dirname(__FILE__) + '/../test_helper'

class BlogCommentTest < ActiveSupport::TestCase

  # 修正可能ユーザチェック
  def test_editable
    current_user = User.make
    comment = BlogComment.make

    assert_equal false, comment.editable?(current_user)


    comment = BlogComment.make(:user => current_user)

    assert_equal true, comment.editable?(current_user)
  end

  # 削除可能ユーザチェック
  def test_deletable
    current_user = User.make
    entry = BlogEntry.make(:user => current_user)
    comment = BlogComment.make(:blog_entry => entry)

    assert_equal true, comment.deletable?(current_user)


    comment = BlogComment.make

    assert_equal false, comment.deletable?(current_user)
  end

  # 自分が書き込んだ最近のコメント取得
  def test_recents_my_comments
    current_user = User.make
    friend = User.make
    current_user.friend!(friend)
    other = User.make

    # トモダチまで公開ブログへコメント
    entry = BlogEntry.make(:user => friend,
                           :visibility => BlogPreference::VISIBILITIES[:friend_only])
    BlogComment.make(:blog_entry => entry, :user => current_user)

    # 公開ブログへコメント
    entry = BlogEntry.make(:user => friend,
                           :visibility => BlogPreference::VISIBILITIES[:publiced])
    BlogComment.make(:blog_entry => entry, :user => current_user)

    assert_equal 2, BlogComment.recents_my_comment(current_user, friend, 5).size
    assert_equal 1, BlogComment.recents_my_comment(current_user, other, 5).size

    # 自分の公開ブログへコメント
    entry = BlogEntry.make(:user => current_user,
                           :visibility => BlogPreference::VISIBILITIES[:publiced])
    BlogComment.make(:blog_entry => entry, :user => current_user)
    assert_equal 2, BlogComment.recents_my_comment(current_user, friend, 5).size

    # 同じブログへのコメント
    dup_user = User.make
    entry = BlogEntry.make(:user => current_user,
                           :visibility => BlogPreference::VISIBILITIES[:publiced])
    BlogComment.make(:blog_entry => entry, :user => dup_user)
    BlogComment.make(:blog_entry => entry, :user => dup_user)
    entry = BlogEntry.make(:user => current_user,
                           :visibility => BlogPreference::VISIBILITIES[:publiced])
    BlogComment.make(:blog_entry => entry, :user => dup_user)
    entry = BlogEntry.make(:user => current_user,
                           :visibility => BlogPreference::VISIBILITIES[:publiced])
    BlogComment.make(:blog_entry => entry, :user => dup_user)

    res = BlogComment.recents_my_comment(dup_user, dup_user, 3)
    assert_equal 3, res.size

    # 自分から見て、自分のコメント履歴の最後にあたるブログへコメントが新たに追加されたとき
    entry = BlogComment.recents_my_comment(current_user, current_user).last.blog_entry
    BlogComment.make(:blog_entry => entry, :user => other, :created_at => 1.days.since)

    res = BlogComment.recents_my_comment(current_user, current_user)
    assert_equal entry.id, res.first.blog_entry_id

    # 自分が一年前に投稿したコメントのブログに、新たにコメントがあったとき
    entry = BlogEntry.make(:user => other, :visibility => BlogPreference::VISIBILITIES[:publiced])
    BlogComment.make(:blog_entry => entry, :user => current_user, :created_at => 1.years.ago)
    BlogComment.make(:blog_entry => entry, :user => other)

    res = BlogComment.recents_my_comment(current_user, current_user)
    assert_equal false, res.any?{|c| c.blog_entry_id == entry.id}
  end

  # 自分のブログへの最近のコメント一覧取得
  def test_recents_my_blog
    current_user = User.make
    friend = User.make
    current_user.friend!(friend)
    other = User.make

    entry = BlogEntry.make(:user => current_user,
                           :visibility => BlogPreference::VISIBILITIES[:friend_only])
    BlogComment.make(:blog_entry => entry, :user => friend)
    assert_equal 1, BlogComment.recents_my_blog(current_user, friend, 5).size
    assert_equal 0, BlogComment.recents_my_blog(current_user, other, 5).size
  end
end

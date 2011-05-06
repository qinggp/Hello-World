require File.dirname(__FILE__) + '/../../test_helper'

class BlogEntriesHelperTest < ActionView::TestCase

  # ブログ本文表示（切り取り）
  def test_display_blog_entry_body_with_trancate_bytes
    entry = BlogEntry.make(:body => "<b>123<i>4567</i>8</b>9")
    assert_match(%Q(<b>123</b>...),
                 display_blog_entry_body(entry, :display_type => :normal, :trancate_bytes => 3))
    assert_match(%Q(<b>123<i>4</i></b>...),
                 display_blog_entry_body(entry, :display_type => :normal, :trancate_bytes => 4))
    assert_match(%Q(<b>123<i>4567</i>8</b>9),
                 display_blog_entry_body(entry, :display_type => :normal, :trancate_bytes => entry.body.length))
    assert_equal(nil, %Q(<b>123<i>4567</i>8</b>9...).match(
                                                           display_blog_entry_body(entry, :display_type => :normal, :trancate_bytes => entry.body.length)))
    assert_match(%Q(<b>123<i>4567</i>8</b>9),
                 display_blog_entry_body(entry, :display_type => :normal))
    assert_equal(nil, %Q(<b>123<i>4567</i>8</b>9...).match(
                                                           display_blog_entry_body(entry, :display_type => :normal)))

    entry = BlogEntry.make_unsaved(:body => "<b>123<i>4567</i>8</b>9", :imported_by_rss => true)
    assert_match(%Q(<b>123<i>4567</i>8</b>9...),
                 display_blog_entry_body(entry, :display_type => :normal, :trancate_bytes => entry.body.length))

    entry = BlogEntry.make_unsaved(:body => "<b><hr></b>")
    assert_match(%Q(<b><hr></b>),
                 display_blog_entry_body(entry, :display_type => :normal, :trancate_bytes => 3))
  end

  private

  # NOTE: application_helperをincludeすると、他のテストが落ちたため、ここではapplication_helper内のメソッドをここで定義し、振る舞いも簡略化させる
  def add_session_query_on_inner_url(str)
    str
  end
end

require File.dirname(__FILE__) + '/../test_helper'

exit unless RankingExtension.instance.extension_enabled?(:blog)

class BlogEntryTest < ActiveSupport::TestCase

  # 最近の人気ブログのランキング取得のテスト
  def test_latest_popular_ranking
    make_default_blog_category

    BlogEntry.destroy_all

    first_blog_access = 1000
    first_blog_comments = 3
    second_blog_access = 10
    second_blog_comments = 1

    first_blog = BlogEntry.make(:access_count => first_blog_access)
    second_blog = BlogEntry.make(:access_count => second_blog_access)
    unpubliced_blog = BlogEntry.make(:visibility =>  BlogPreference::VISIBILITIES[:unpubliced])  # これは表示されない
    too_old_blog = BlogEntry.make(:created_at => Date.today << 1)  # これも表示されない

    first_blog_comments.times { BlogComment.make(:blog_entry => first_blog) }
    second_blog_comments.times { BlogComment.make(:blog_entry => second_blog) }

    blog_entries = BlogEntry.popular_ranking(10, :start_date => Time.now.ago(60 * 60 * 24 * 3).beginning_of_day, :end_date => Time.now.end_of_day)

    assert_equal 2, blog_entries.length
    assert_equal first_blog_comments + first_blog_access, blog_entries.first.count.to_i
    assert_equal second_blog_comments + second_blog_access, blog_entries.second.count.to_i
  end
end

require File.dirname(__FILE__) + '/../test_helper'

# ブログカテゴリテスト
class BlogCategoryTest < ActiveSupport::TestCase
  # ブログカテゴリ削除時にカテゴリを付け替える
  def test_before_destroy
    category = BlogCategory.make
    entry = BlogEntry.make(:blog_category => category)
    assert_not_nil entry.blog_category
    category.destroy
    entry.reload
    assert_equal BlogCategory.default_category, entry.blog_category
  end
end

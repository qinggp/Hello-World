require File.dirname(__FILE__) + '/../test_helper'

class BlogPreferenceTest < ActiveSupport::TestCase

  # 外部RSSの正当性チェック
  def test_valid_rss_url
    pre = BlogPreference.make_unsaved(:rss_url => File.join(RAILS_ROOT, "test/fixtures/files/invalid.atom"))
    assert_equal false, pre.valid?
    assert_not_nil pre.errors[:rss_url]
  end

  # メール投稿の場合のコメント制限テスト
  def test_comment_restraint_for_email
    user = User.make
    BlogPreference::VISIBILITIES.each do |key, value|
      user.preference.blog_preference.update_attributes!(:visibility => value,
                                                         :email_post_visibility => value)

      if key == :publiced
        assert BlogPreference::VISIBILITIES[:member_only], user.preference.blog_preference.comment_restraint_for_email
      else
        assert value, user.preference.blog_preference.comment_restraint_for_email
      end
    end
  end
end

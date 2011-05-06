require File.dirname(__FILE__) + '/../test_helper'

class SnsLinkageTest < ActiveSupport::TestCase

  # SNS連携RSSデータ取得
  def test_sns_link_data
    l = SnsLinkage.make
    assert_not_nil l.sns_link_info_data
    assert_not_nil l.sns_link_news_data
    assert_not_nil l.sns_link_notice_data
    assert_not_nil l.name
    assert_not_nil l.url

  end

  # SNS連携データ検証チェック
  def test_sns_linkage_validates
    l = SnsLinkage.new(SnsLinkage.plan(:key => "hoge"))
    assert_equal false, l.valid?
    assert_not_nil l.errors[:key]

    l = SnsLinkage.make
    duplicate_key_l = SnsLinkage.new(SnsLinkage.plan(:key => l.key))
    duplicate_key_l.user = l.user
    assert_equal false, duplicate_key_l.valid?
    assert_not_nil duplicate_key_l.errors[:key]

    stub(Mars::SnsLinkage::RssParser).read_rss do
      result = IO.read(File.dirname(__FILE__) + '/../fixtures/test_rss_invalid.rss')
    end

    l = SnsLinkage.new(SnsLinkage.plan(:key => "hoge"))
    assert_equal false, l.valid?
    assert_not_nil l.errors[:key]
  end
end

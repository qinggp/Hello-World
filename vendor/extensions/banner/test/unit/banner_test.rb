require File.dirname(__FILE__) + '/../test_helper'

class BannerTest < ActiveSupport::TestCase
  # Replace this with your real tests.

  # 入力必須チェック
  def test_validate_presence_of
    banner = Banner.new
    assert !banner.valid?
    assert banner.errors.invalid?(:comment)
    assert banner.errors.invalid?(:image)
  end

  # コメントの文字数チェック
  def test_validates_length_of
    banner = validate_check_data

    assert !banner.valid?
    assert banner.errors.invalid?(:comment)
  end

  # リンクURLのアドレス形式チェック
  def test_validate_format_of
    banner = validate_check_data
    assert !banner.valid?
    assert banner.errors.invalid?(:link_url)
  end

  # 添付ファイルのエラーチェック（サイズ、拡張子）
  def test_validate_file_format_of
    banner = validate_check_data
    assert !banner.valid?
    assert banner.errors.invalid?(:image)
  end

  # リンクURLが空ならfalseを返すメソッドのテスト
  def test_link_url_not_blank
    banner = Banner.new
    assert_equal false, banner.link_url_not_blank?

    banner = Banner.new(:link_url => 'http://test.com')
    assert_equal true, banner.link_url_not_blank?
  end

  def validate_check_data
    Banner.new({:comment => '1' * 255,
                :link_url => 'errors.com',
                :image => upload("#{RAILS_ROOT}/public/images/rails.png")
      })
  end

end

require File.dirname(__FILE__) + '/../test_helper'

class InformationTest < ActiveSupport::TestCase

  #保存が行われ件数が1増えるかテスト
  def test_should_create_information
    assert_difference 'Information.count' do
      information = Information.make
      assert !information.new_record?, "#{information.errors.full_messages.to_sentence}"
    end
  end

  #titleが未入力ならエラーが発生するかテスト
  def test_should_require_title
    assert_no_difference 'Information.count' do
      u = Information.make_unsaved(:title => nil)
      u.save
      assert u.errors.on(:title)
    end
  end

  #expire_dateが未入力ならエラーが発生するかテスト
  def test_should_require_expire_date
    assert_no_difference 'Information.count' do
      u = Information.make_unsaved(:expire_date => nil)
      u.save
      assert u.errors.on(:expire_date)
    end
  end

  #display_linkが期待する数値以外の時エラー発生
  def test_should_inclusion_of_display_link
    assert_no_difference 'Information.count' do
      u = Information.make_unsaved(:display_link => 234)
      u.save
      assert u.errors.on(:display_link)
    end
  end

  #display_typeが期待する数値以外の時エラー発生
  def test_should_inclusion_of_display_type
    assert_no_difference 'Information.count' do
      u = Information.make_unsaved(:display_type => 345)
      u.save
      assert u.errors.on(:display_type)
    end
  end

  #public_rangeが期待する数値以外の時エラー発生
  def test_should_inclusion_of_public_range
    assert_no_difference 'Information.count' do
      u = Information.make_unsaved(:public_range => 456)
      u.save
      assert u.errors.on(:public_range)
    end
  end
end

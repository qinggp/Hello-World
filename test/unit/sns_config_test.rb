require File.dirname(__FILE__) + '/../test_helper'

class SnsConfigTest < ActiveSupport::TestCase
  #titleが未入力ならエラーが発生するかテスト
  def test_should_require_title
    assert_no_difference 'SnsConfig.count' do
      u = update_sns_config(:title => nil)
      assert u.errors.on(:title)
    end
  end
  #outlineが未入力ならエラーが発生するかテスト
  def test_should_require_outline
    assert_no_difference 'SnsConfig.count' do
      u = update_sns_config(:outline => nil )
      assert u.errors.on(:outline)
    end
  end
  #admin_mail_addressが未入力ならエラーが発生するかテスト
  def test_should_require_admin_mail_address
    assert_no_difference 'SnsConfig.count' do
      u = update_sns_config(:admin_mail_address => nil)
      assert u.errors.on(:admin_mail_address)
    end
  end
  #entry_typeが未入力ならエラーが発生するかテスト
  def test_should_require_entry_type
    assert_no_difference 'SnsConfig.count' do
      u = update_sns_config(:entry_type => nil)
      assert u.errors.on(:entry_type)
    end
  end
  #invite_typeが未入力ならエラーが発生するかテスト
  def test_should_require_invite_type
    assert_no_difference 'SnsConfig.count' do
      u = update_sns_config(:invite_type => nil)
      assert u.errors.on(:invite_type)
    end
  end
  #approval_typeが未入力ならエラーが発生するかテスト
  def test_should_require_approval_type
    assert_no_difference 'SnsConfig.count' do
      u = update_sns_config(:approval_type => nil)
      assert u.errors.on(:approval_type)
    end
  end
  #login_display_typeが未入力ならエラーが発生するかテスト
  def test_should_require_login_display_type
    assert_no_difference 'SnsConfig.count' do
      u = update_sns_config(:login_display_type => nil)
      assert u.errors.on(:login_display_type)
    end
  end
  #relation_flgが未入力ならエラーが発生するかテスト
  def test_should_require_relation_flg
    assert_no_difference 'SnsConfig.count' do
      u = update_sns_config(:relation_flg => nil)
      assert u.errors.on(:relation_flg)
    end
  end

  #outlineが100文字以上の時エラーが発生するかチェック
  def test_should_length_of_outline
    assert_no_difference 'SnsConfig.count' do
      array = String.new
      101.times {array += "a"}
      u = update_sns_config(:outline => array)
      assert u.errors.on(:outline)
    end
  end
  #titleが100文字以上の時エラーが発生するかチェック
  def test_should_length_of_title
    assert_no_difference 'SnsConfig.count' do
      array = String.new
      101.times {array += "a"}
      u = update_sns_config(:title => array)
      assert u.errors.on(:title)
    end
  end
  #admin_mail_addressが100文字以上の時エラーが発生するかチェック
  def test_should_length_of_admin_mail_address
    assert_no_difference 'SnsConfig.count' do
      array = String.new
      101.times {array += "a"}
      u = update_sns_config(:admin_mail_address => array)
      assert u.errors.on(:admin_mail_address)
    end
  end

  protected
  def update_sns_config(options = {})
    record = SnsConfig.find(:first)
    record.attributes = {:title => "SNS_NAME",:outline => "SNS_OUTLINE",:admin_mail_address => "admin@example.com",:entry_type => 1,:invite_type => 1,:approval_type => 1,:login_display_type => 1,:relation_flg => 1}.merge(options)
    record.save
    record
  end
end

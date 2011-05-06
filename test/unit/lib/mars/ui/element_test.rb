require File.dirname(__FILE__) + '/../../../../test_helper'

# Elementテスト
class ElementTest < ActiveSupport::TestCase

  # 初期化
  test "initialize" do
    elm = Mars::UI::Element.new(:name)
    assert_equal :name, elm.name
    assert_equal [:all], elm.visibility

    elm = Mars::UI::Element.new(:name, :for => [:admin], :visibility => [:developer])
    assert_equal :name, elm.name
    assert_equal [:admin, :developer], elm.visibility
  end

  # 要素可視性チェック
  test "shown_for" do
    user = User.new
    stub(user).admin?{ true }
    elm = Mars::UI::Element.new(:name, :for => [:admin])
    assert_equal true, elm.shown_for?(user)

    stub(user).admin?{ false }
    assert_equal false, elm.shown_for?(user)
  end
end


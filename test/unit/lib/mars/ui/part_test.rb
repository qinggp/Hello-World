require File.dirname(__FILE__) + '/../../../../test_helper'

# UI部分テンプレートテスト
class Mars::UI::PartTest < ActiveSupport::TestCase

  # 初期化
  test "initialize" do
    elm = Mars::UI::Part.new(:test_basic,
                             :element_set_id => "test_basic",
                             :extension => TestBasicExtension.instance)
    assert_equal :test_basic, elm.name
    assert_equal "#{elm.default_part_dirname}/#{elm.element_set_id}/test_basic", elm.partial
  end

  # 部分テンプレート表示
  test "display" do
    view = ActionView::Base.new
    stub(view.helpers).include{|helper| @helper = helper}
    stub(view).render{|opt| @part = opt[:partial]}

    elm = Mars::UI::Part.new(:test_basic,
                             :extension => TestBasicExtension.instance)
    elm.display(view)

    assert_equal TestBasicPartHelper, @helper
    assert_equal "#{elm.default_part_dirname}/test_basic", @part
  end
end

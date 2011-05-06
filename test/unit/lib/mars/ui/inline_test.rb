require File.dirname(__FILE__) + '/../../../../test_helper'

# UIインラインテンプレートテスト
class Mars::UI::PartTest < ActiveSupport::TestCase

  # インラインテンプレート表示
  def test_display
    view = ActionView::Base.new
    mock(view).current_user{ User.make }
    elm = Mars::UI::Inline.new(:test_basic,
                             :inline => "<%= 1 + 1 %>")
    assert_equal "2", elm.display(view)
  end
end

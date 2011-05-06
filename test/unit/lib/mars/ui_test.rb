require File.dirname(__FILE__) + '/../../../test_helper'

# UIクラステスト
class UITest < ActiveSupport::TestCase
  def setup
    @ui = Mars::UI.instance
  end

  test "initializer" do
    assert_instance_of Mars::UI::ElementSet, @ui.profile_contents
    assert_instance_of Mars::UI::ElementSet, @ui.my_menus
  end
end

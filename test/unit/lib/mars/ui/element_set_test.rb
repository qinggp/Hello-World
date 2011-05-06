require File.dirname(__FILE__) + '/../../../../test_helper'

# ElementSetクラステスト
class ElementSetTest < ActiveSupport::TestCase
  def setup
    @element_set = Mars::UI::ElementSet.new("element_set", Mars::UI::Link)
  end

  # 要素追加
  test "add" do
    @element_set.add :link, :url => {:controller => :blog_entries}
    assert_instance_of Mars::UI::Link, @element_set[:link]
    @element_set.add(:test_basic,
                     :helper => :test_basic_helper,
                     :type => "part")
    assert_instance_of Mars::UI::Part, @element_set[:test_basic]
  end

  # 要素追加失敗
  #
  # 追加する要素キーが重複していた場合
  test "add fail with duplicate key" do
    @element_set.add :name, :url => {:controller => :blog_entries}
    assert_raise Mars::UI::ElementSet::DuplicateElementNameError do
      @element_set.add :name, :url => {:controller => :blog_entries}
    end
  end
end

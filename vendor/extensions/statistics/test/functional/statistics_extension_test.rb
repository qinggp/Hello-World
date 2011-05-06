require File.dirname(__FILE__) + '/../test_helper'

class StatisticsExtensionTest < Test::Unit::TestCase

  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'statistics'), StatisticsExtension.instance.root
    assert_equal 'Statistics', StatisticsExtension.instance.extension_name
  end
end

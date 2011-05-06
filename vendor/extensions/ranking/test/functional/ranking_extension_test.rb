require File.dirname(__FILE__) + '/../test_helper'

class RankingExtensionTest < ActionController::TestCase

  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'ranking'), RankingExtension.instance.root
    assert_equal 'Ranking', RankingExtension.instance.extension_name
  end
end

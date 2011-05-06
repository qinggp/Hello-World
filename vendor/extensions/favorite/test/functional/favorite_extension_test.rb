require File.dirname(__FILE__) + '/../test_helper'

class FavoriteExtensionTest < ActionController::TestCase
  
  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'favorite'), FavoriteExtension.instance.root
    assert_equal 'Favorite', FavoriteExtension.instance.extension_name
  end
end

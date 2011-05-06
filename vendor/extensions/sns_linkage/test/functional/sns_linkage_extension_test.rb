require File.dirname(__FILE__) + '/../test_helper'

class SnsLinkageExtensionTest < ActionController::TestCase
  
  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'sns_linkage'), SnsLinkageExtension.instance.root
    assert_equal 'SnsLinkage', SnsLinkageExtension.instance.extension_name
  end
  
end

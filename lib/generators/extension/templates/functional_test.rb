require File.dirname(__FILE__) + '/../test_helper'

class <%= class_name %>Test < ActionController::TestCase
  
  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', '<%= file_name %>'), <%= class_name %>.instance.root
    assert_equal '<%= extension_name %>', <%= class_name %>.instance.extension_name
  end
  
end

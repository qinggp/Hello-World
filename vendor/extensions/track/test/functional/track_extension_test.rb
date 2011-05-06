require File.dirname(__FILE__) + '/../test_helper'

class TrackExtensionTest < ActionController::TestCase

  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'track'), TrackExtension.instance.root
    assert_equal 'Track', TrackExtension.instance.extension_name
  end

end

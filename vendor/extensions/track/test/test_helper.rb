ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require "#{RAILS_ROOT}/test/test_helper"
require File.expand_path(File.dirname(__FILE__) + "/helpers/enable_multiple_fixture_paths")

class ActiveSupport::TestCase
  # Add the fixture directory to the fixture path
  self.fixture_paths = [
    File.join(File.dirname(__FILE__), "fixtures"),
    File.join(::Rails.root, 'test/fixtures')
  ]
  self.fixture_path = File.join(::Rails.root, 'test/fixtures/')

  fixtures :all

  # Add more helper methods to be used by all extension tests here...
end

require File.expand_path(File.dirname(__FILE__) + "/blueprints")

# 現在の時間であしあとを作っていくと、validationでひっかかるので、
# 一年前からデフォルト3000秒間隔であしあとを作成する。
def track_make(options={})
  @created_at ||= Time.now - 60 * 60 * 24 * 365 * 3   # 3年前からスタート
  interval = options.delete(:interval) || 3000

  Track.make(options.merge(:created_at => (@created_at += interval)))
end



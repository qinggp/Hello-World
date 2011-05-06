ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require "#{RAILS_ROOT}/test/test_helper"
require File.expand_path(File.dirname(__FILE__) + "/helpers/enable_multiple_fixture_paths")

class ActiveSupport::TestCase
  # 使用するフィクスチャファイルの探索パスを設定．
  self.fixture_paths = [
    File.join(File.dirname(__FILE__), "fixtures"),
    File.join(::Rails.root, 'test/fixtures')
  ]
  self.fixture_path = File.join(::Rails.root, 'test/fixtures/')

  fixtures :all
end

require File.expand_path(File.dirname(__FILE__) + "/blueprints")

def set_community_and_has_role(*args)
  member = args.first.is_a?(User) ? args.shift : @current_user
  role = args.first.is_a?(String) ? args.shift : "community_admin"
  attributes = args.first.is_a?(Hash) ? args.shift : { }
  community = Community.make(attributes)
  community.members << member
  member.has_role!(role, community)
  community
end

# コミュニティ、イベントを作成し、イベントにmemberを参加させる
def set_community_event_and_members(member, author = @current_user)
  # コミュニティを作成する
  community = set_community_and_has_role(author)

  # イベントを作成する
  event = CommunityEvent.make(:community => community, :author => author)

  # membersをコミュニティ、及びイベントの参加メンバーにする
  members = Array.wrap(member)
  members.each do |member|
    community.members << member
    member.has_role!("community_general", community)
    event.participate_in(member)
  end
  event
end

# コミュニティを作成し、それににmemberを参加させる
def set_community_and_members(member, author = @current)
  community = set_community_and_has_role(author)

  members = Array.wrap(member)
  members.each do |member|
    community.members << member
    member.has_role!("community_general", community)
  end
  community
end

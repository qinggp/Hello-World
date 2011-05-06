# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_map_categories
#
#  id           :integer         not null, primary key
#  name         :string(255)
#  user_id      :integer
#  community_id :integer
#  created_at   :datetime
#  updated_at   :datetime
#

class CommunityMapCategory < ActiveRecord::Base
  has_many :community_markers, :class_name => "CommunityMarker"
  belongs_to :community
  belongs_to :author, :foreign_key => "user_id", :class_name => "User"

  validates_presence_of :name

  @@default_index_order = 'community_map_categories.created_at DESC'
  cattr_reader :default_index_order

  after_destroy :change_marker_to_topic

  #マップカテゴリ所有権を委譲する
  #(comunity_map_category)
  #引数:委譲元の管理者のuser_id, 委譲先になる管理者のuser_id, 変更対象のcommunity_id
  #戻り値:
  def self.change_user!(old_user_id, new_user_id, community_id)
    self.update_all("user_id = '#{new_user_id}'", ["community_id = ? AND user_id = ?", community_id, old_user_id])
  end

  private

  # 削除されたとき、自分に属すマーカーをトピックへと変更する
  def change_marker_to_topic
    community_markers.each do |marker|
      marker.become_topic!
    end
  end
end

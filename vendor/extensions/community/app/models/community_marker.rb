# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_threads
#
#  id                        :integer         not null, primary key
#  title                     :string(255)
#  content                   :text
#  event_date                :date
#  event_date_note           :string(255)
#  place                     :string(255)
#  latitude                  :decimal(9, 6)
#  longitude                 :decimal(9, 6)
#  zoom                      :integer
#  user_id                   :integer
#  community_id              :integer
#  public                    :boolean
#  community_map_category_id :integer
#  type                      :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  lastposted_at             :datetime
#

class CommunityMarker < CommunityThread
  belongs_to :map_category, :foreign_key => "community_map_category_id",
             :class_name => "CommunityMapCategory"

  @@presence_of_columns = [:title, :content, :latitude, :longitude, :zoom, :community_map_category_id]
  validates_presence_of @@presence_of_columns
  cattr_reader :presence_of_columns

  named_scope :by_latitude_range, lambda { |lat_start, lat_end|
    {:conditions => ["latitude > ? AND latitude < ?", lat_start, lat_end]}
  }

  named_scope :by_longitude_range, lambda { |lng_start, lng_end|
    {:conditions => ["longitude > ? AND longitude < ?", lng_start, lng_end]}
  }

  # 携帯でコミュニティマップを表示した際の、デフォルトの緯度・経度の表示範囲
  DEFAULT_SPAN_LAT = 0.1
  DEFAULT_SPAN_LNG = 0.1

  # イベントを表すアイコンのパスを返す
  def icon_path
    "map_pin.png"
  end

  # コミュニティをマーカー数でソートする場合にマーカー数をカウントするSQLを返す
  # order by句のサブクエリとして使用する
  def self.sql_for_sort_by_count
    %Q(SELECT count(*) FROM community_threads WHERE communities.id = community_threads.community_id AND community_threads.type = 'CommunityMarker')
  end

  # マーカーからからトピックになる
  # NOTE: 素直にsaveするとマーカーのvalidationで引っかかるので、ここはvalidationをかけないでsaveする
  def become_topic!
    self.attributes = {:community_map_category_id => nil,
                       :latitude => nil,
                       :longitude => nil,
                       :zoom => nil,
                       :kind => "CommunityTopic"}
    self.save_without_validation!
  end
end

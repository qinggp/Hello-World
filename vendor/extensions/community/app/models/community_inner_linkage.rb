# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_linkages
#
#  id           :integer         not null, primary key
#  community_id :integer
#  user_id      :integer
#  link_id      :integer
#  rss_url      :string(255)
#  comment      :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  type         :string(255)
#

class CommunityInnerLinkage < CommunityLinkage
  @@presence_of_columns = [:link_id]
  cattr_accessor :presence_of_columns

  validates_presence_of @@presence_of_columns

  validates_uniqueness_of :link_id, :scope => :community_id

  def validate
    unless Community.exists?(self.link_id)
      self.errors.add(:link_id, "は存在しないコミュニティです。")
    end
    if self.link_id == self.community_id
      self.errors.add(:link_id, "は自分自身をリンクできません。")
    end
  end

  # リンク種別
  def link_type
    "内部"
  end

  # リンク先のURL
  def url(view)
    view.send("community_path", (self.inner_link))
  end

  # リンクの名前
  def name
    self.inner_link.name
  end

  # 内部リンクを表すアイコン返す
  def icon(view)
    ""
  end

  # リンク先の新着情報（マーカー、トピック、イベント）を取得する
  #
  # ==== 引数
  #
  # * view - 表示を行うview
  # * limit - 表示最大件数
  #
  # ==== 戻り値
  #
  # ハッシュを要素とする配列。ハッシュは以下をkeyとする。
  #
  # * updated_at - 最終更新日時
  # * title - コミュニティのタイル
  # * url_to_linkage - コミュニティへのurl
  # * content - スレッドのタイトル
  # * url_to_article - スレッドへのurl
  # * image - リンクイメージ図
  def news(view, limit = 20)
    unsorted_news =
      self.inner_link.threads_order_by_post(limit).map do |t|
      {:updated_at => t.lastposted_at, :title => self.inner_link.name, :content => t.title,
        :url_to_linkage => view.send("community_path", self.inner_link.id),
        :url_to_article => t.polymorphic_url_on_community(view),
        :image => "",
        :type => "CommunityInnerLinkage"}
    end

    unsorted_news.sort_by{|hash| hash[:updated_at] }.reverse.slice(0, limit)
  end
end

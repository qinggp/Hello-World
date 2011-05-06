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

require 'rss'

class CommunityOuterLinkage < CommunityLinkage
  @@presence_of_columns = [:rss_url]
  cattr_reader :presence_of_columns

  attr_accessor :rss

  validates_presence_of @@presence_of_columns

  validates_uniqueness_of :rss_url, :scope => :community_id

  def validate
    unless parse
      self.errors.add(:rss_url, "を取得できません。")
    end
  end

  # リンク種別
  def link_type
    "外部"
  end

  # リンクの名前
  def name
    return "取得できません" unless parse

    if @rss.class == ::RSS::Atom::Feed
      @rss.title.content
    else
      @rss.channel.title
    end
  end

  # 外部リンクを表すアイコン返す
  def icon(view)
    view.theme_image_tag("community/outlink.gif", :border => 0)
  end

  # リンク先のURL
  def url(view)
    rss_url
  end

  # rss_urlに対して、実際にRSSを取得し、parseする
  # parseできない場合は、nilを返す
  def parse
    @rss = RSS::Parser.parse(read_rss, false)
  rescue Exception => ex
    Rails.logger.error{ "ERROR: #{ex.class} : #{ex.message}" }
    return nil
  end

  # リンク先のRSSから新着情報を取得する
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
  # * title - RSSのタイル
  # * url_to_linkage - RSS発行元へのリンク
  # * content - 記事のタイトル
  # * url_to_article - 記事へのURL
  # * image - リンクイメージ図
  def news(view, limit = 20)
    return [] unless parse

    image = icon(view)

    unsorted_news =
    if @rss.class == ::RSS::Atom::Feed
      @rss.entries.map do |e|
        {:updated_at => e.updated.content, :title => @rss.title.content,
          :url_to_article => e.link.href,
          :content => e.title.content,
          :image => image,
          :url_to_linkage => @rss.link.href,
          :type => "CommunityOuterLinkage"}
      end
    else
      @rss.items.map do |e|
        {:updated_at => e.date, :title => @rss.channel.title,
          :url_to_article => e.link,
          :image => image,
          :content => e.title,
          :url_to_linkage => @rss.channel.link,
          :type => "CommunityOuterLinkage"}
      end
    end

    unsorted_news.sort_by{|hash| hash[:updated_at] }.reverse.slice(0, limit)
  end

  private

  def read_rss
    open(self.rss_url) do |http|
      return http.read
    end
  end
end

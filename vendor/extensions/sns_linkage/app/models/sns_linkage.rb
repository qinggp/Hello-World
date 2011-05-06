# == Schema Information
# Schema version: 20100227074439
#
# Table name: sns_linkages
#
#  id         :integer         not null, primary key
#  key        :string(255)
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  name       :text
#  url        :text
#

require 'digest/sha1'

# SNS連携キー保持
class SnsLinkage < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :key
  validates_format_of :key, :with => /https?:\/\/.*\/\?[0-9a-z]*/
  validates_uniqueness_of :key, :scope => [:user_id]
  validate :valid_key_not_same_host?
  validate :valid_key_get_any_data?

  attr_accessible :key

  # SNS連携キー設定
  def self.set_link_key!(user)
    user.sns_link_key =
      Digest::SHA1.hexdigest([user.private_token,user.id,user.name,Time.now].join('--'))
  end

  # SNS連携告知情報データ取得(info)
  def sns_link_info_data
    @sns_link_info_data ||= sns_link_data(self.key+".info")
    return @sns_link_info_data
  end

  # SNS連携新着情報データ取得(news)
  def sns_link_news_data
    @sns_link_news_data ||= sns_link_data(self.key+".news")
    return @sns_link_news_data
  end

  # SNS連携お知らせ情報データ取得(notice)
  def sns_link_notice_data
    @sns_link_notice_data ||= sns_link_data(self.key+".notice")
    return @sns_link_notice_data
  end

  # SNS連携RSSデータ取得
  def rss_channel
    sns_link_notice_data.channel
  end

  # SNS連携RSSデータ画像パス
  def sns_link_data_image_url
    if rss_channel.image
      rss_channel.image.url
    else
      "sns_linkage/noimage.png"
    end
  end

  # SNS連携RSSデータ画像リンク
  def sns_link_data_image_link
    if rss_channel.image
      rss_channel.image.link
    else
      rss_channel.link
    end
  end

  # SNS連携先のキーは発行停止になっていないか？
  def sns_link_enable?
    return !sns_link_notice_data.nil?
  end

  # 有効なSNS連携データリスト
  def self.by_enableds(user_id)
    self.user_id_is(user_id).
      descend_by_created_at.select{|sl| sl.sns_link_enable?}
  end

  # 保存前処理
  def before_save
    self.name = rss_channel.title
    self.url = self.rss_channel.link
  end

  private

  # 自SNSの連携キーではないか？
  def valid_key_not_same_host?
    if self.key.include?(CONFIG['host'])
      self.errors.add(:key, "は同じSNS内の連携キーです。")
      return false
    end
    return true
  end

  # SNS連携データは取得できるか？
  def valid_key_get_any_data?
    unless sns_link_enable?
      self.errors.add(:key, "から連携データを取得することができませんでした。")
      return false
    end
    return true
  end

  def sns_link_data(url)
    Mars::SnsLinkage::RssParser.parse(url) unless self.key.blank?
  end
end

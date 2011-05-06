
# == Schema Information
# Schema version: 20100227074439
#
# Table name: blog_entries
#
#  id                  :integer         not null, primary key
#  user_id             :integer
#  title               :string(255)
#  body                :text
#  created_at          :datetime
#  updated_at          :datetime
#  body_format         :string(255)
#  visibility          :integer
#  comment_restraint   :integer
#  blog_category_id    :integer
#  access_count        :integer         default(0)
#  longitude           :decimal(9, 6)
#  latitude            :decimal(9, 6)
#  zoom                :integer
#  blog_comments_count :integer         default(0)
#

require 'rss'

# ブログ記事
class BlogEntry < ActiveRecord::Base
  belongs_to :user
  belongs_to :blog_category

  has_many :blog_comments, :dependent => :destroy, :order => BlogComment.default_index_order
  has_many :blog_attachments, :dependent => :destroy, :validate => false

  accepts_nested_attributes_for :blog_attachments, :allow_destroy => true

  # フォーマット名（WYSWYG）
  BODY_FORMAT_WYSWIG = "wyswyg"

  # フォーマット名（タグをそのまま表示）
  BODY_FORMAT_NO_ESCAPE = "no_escape"

  named_scope :by_user, lambda{|user| {:conditions => ["blog_entries.user_id = ?", user.id] }}
  named_scope :by_user_friends, lambda{|user|
    {:conditions => ["blog_entries.user_id in (?)", user.friends.map(&:id)], :order => "created_at ASC"}
  }
  # 指定ユーザが閲覧可能なブログ取得
  named_scope :by_visible_for_user, lambda{|user, include_unpubliced|
    {:conditions => by_visible_for_user_condition(user, include_unpubliced)}
  }
  named_scope :by_latitude_range, lambda { |lat_start, lat_end|
    {:conditions => ["latitude > ? AND latitude < ?", lat_start, lat_end]}
  }
  named_scope :by_longitude_range, lambda { |lng_start, lng_end|
    {:conditions => ["longitude > ? AND longitude < ?", lng_start, lng_end]}
  }
  # 最近の記事
  named_scope :recents, lambda { |limit, day_ago|
    conds = []
    conds = ["created_at > ?", day_ago] if day_ago
    {:conditions => conds,
      :order => "created_at DESC", :limit => limit}
  }
  named_scope :by_new_blog_entry_displayed_for_user, lambda {|user|
    ids = Friendship.user_id_is(user.id).
            new_blog_entry_displayed_is(true).
            approved_is(true).map(&:friend_id)
    {:conditions => ["blog_entries.user_id in (?)", ids]}
  }
  named_scope :by_activate_users, lambda{
    {:conditions => ["users.approval_state = ?", 'active'], :include => [:user]}
  }
  named_scope :by_sns_member_visible, lambda {
    {:conditions => ["blog_entries.visibility in (?)",
                     [BlogPreference::VISIBILITIES[:publiced],
                      BlogPreference::VISIBILITIES[:member_only],
                      BlogPreference::VISIBILITIES[:friend_only]]]}
  }
  named_scope :by_now_month, lambda {
    {:conditions => ["blog_entries.created_at >= ? AND blog_entries.created_at < ?",
                     Date.today.beginning_of_month.to_time, 1.month.since.beginning_of_month.to_time]}
  }

  @@default_index_order = 'blog_entries.created_at DESC'
  @@presence_of_columns = [:title, :body, :blog_category]

  validates_presence_of @@presence_of_columns
  validates_presence_of :latitude, :if => Proc.new{|model| model.longitude || model.zoom }
  validates_presence_of :longitude, :if => Proc.new{|model| model.latitude || model.zoom }
  validates_presence_of :zoom, :if => Proc.new{|model| model.latitude || model.longitude }
  validates_inclusion_of :body_format, :in => [BODY_FORMAT_WYSWIG, BODY_FORMAT_NO_ESCAPE],
                         :allow_nil => true, :allow_blank => true
  validates_inclusion_of :visibility, :in => BlogPreference::VISIBILITIES.values
  validates_inclusion_of :comment_restraint, :in => BlogPreference::VISIBILITIES.values
  validates_associated :blog_attachments
  validate :valid_total_filesize_of_attachments?

  attr_accessor :search_word, :imported_by_rss, :url_to_article, :rss_title, :rss_url
  attr_protected :updated_at, :blog_comments_count
  cattr_reader :default_index_order, :presence_of_columns

  # 本文の設定（WYSWIG）
  #
  # ==== 引数
  #
  # * str - 内容
  def body_by_wyswyg=(str)
    self.body = str
    self.body_format = BODY_FORMAT_WYSWIG
  end

  # 本文返却（WYSWIG）
  def body_by_wyswyg
    self.body
  end

  # 公開制限名を取得
  #
  # ==== 戻り値
  #
  # 公開制限名
  def visibility_name
    return BlogPreference::VISIBILITIES.invert[visibility]
  end

  # コメント制限名を取得
  #
  # ==== 戻り値
  #
  # コメント制限名
  def comment_restraint_name
    return BlogPreference::VISIBILITIES.invert[comment_restraint]
  end

  # visibility_publiced? などの状態を判別するメソッド
  BlogPreference::VISIBILITIES.each do |key, value|
    define_method("visibility_#{key}?") do
      return self.visibility == value
    end
  end

  # comment_restraint_publiced? などの状態を判別するメソッド
  BlogPreference::VISIBILITIES.each do |key, value|
    define_method("comment_restraint_#{key}?") do
      return self.comment_restraint == value
    end
  end

  # 記事を閲覧可能か？
  #
  # ==== 引数
  #
  # * current_user - ログイン中ユーザ or nil
  #
  # ==== 戻り値
  #
  # true/false
  def visible?(current_user=nil)
    return true if current_user == user
    case
    when anonymous_viewable?
      return true
    when member_viewable?
      return !current_user.nil?
    when friend_viewable?
      return false if current_user.nil?
      return current_user.friend_user?(user)
    else
      return false
    end
  end

  # 記事へコメント可能か？
  #
  # ==== 引数
  #
  # * current_user - ログイン中ユーザ or nil
  #
  # ==== 戻り値
  #
  # true/false
  def commentable?(current_user=nil)
    case
    when comment_restraint_publiced?
      return true
    when comment_restraint_member_only?
      return !current_user.nil?
    when comment_restraint_friend_only?
      return true if current_user == user
      return false if current_user.nil?
      return current_user.friend_user?(self.user)
    when comment_restraint_unpubliced?
      return false
    end
  end

  # 匿名ユーザは閲覧可能か？
  def anonymous_viewable?
    (user.preference.blog_preference.anonymous_viewable? &&
     visibility_publiced?)
  end

  # SNSメンバは閲覧可能か？
  def member_viewable?
    (user.preference.blog_preference.member_viewable? &&
      (visibility_publiced? || visibility_member_only?))
  end

  # トモダチは閲覧可能か？
  def friend_viewable?
    (user.preference.blog_preference.friend_viewable? &&
      (visibility_publiced? || visibility_member_only? || visibility_friend_only?))
  end

  # フォーム添付ファイル生成
  def build_blog_attatchments
    3.times do |i|
      attachment = self.blog_attachments.detect{|a| i+1 == a.position}
      if attachment.nil?
        self.blog_attachments.build(:position => i+1)
      elsif !self.blog_attachments[i].new_record? && self.blog_attachments[i].image_changed?
        # NOTE: 確認画面からバリデーション失敗で戻ってきた時に画像パスをクリアするため
        self.blog_attachments[i] = BlogAttachment.find(self.blog_attachments[i].id)
      end
    end
  end

  def sorted_blog_attachments
    self.blog_attachments.sort_by{|a| a.position}
  end

  # ブログ公開範囲、コメント制限の範囲を狭める
  def self.visibility_narrow_down(user, visibility)
    records = self.find(:all, :conditions => ["visibility > ? AND user_id = ?", visibility, user.id])
    records.each do |record|
      record.visibility = visibility
      record.save(false)
    end
    records = self.find(:all, :conditions => ["comment_restraint > ? AND user_id = ?", visibility, user.id])
    records.each do |record|
      record.comment_restraint = visibility
      record.save(false)
    end
  end

  # 指定ユーザ閲覧可能ブログ記事一覧取得
  def self.by_visible(current_user, include_unpubliced=true)
    return self.by_visible_for_user(current_user, include_unpubliced) if current_user
    return self.visibility_is(BlogPreference::VISIBILITIES[:publiced])
  end

  # 地図を表示可能か？
  def map_viewable?
    !(latitude.nil? || longitude.nil? || zoom.nil?)
  end

  # 外部RSSのURLから取得したエントリをブログエントリリストにマージ
  def self.merge_imported_entries_by_rss(url, entries=[], options={})
    return entries if url.blank?
    entries += imported_entries_by_rss(url, options[:user])
    return entries.sort_by{|e| -e.created_at.to_i }
  end

  # 外部のRSSのURLデータからそのトップページへのリンクを生成
  def self.link_to_external_blog(view, url)
    entries = imported_entries_by_rss(url)
    if entries.blank?
      ""
    else
      view.link_to entries.first.rss_title.untaint, entries.first.rss_url
    end
  end

  # 指定ユーザが閲覧可能なブログを取得するcondition
  def self.by_visible_for_user_condition(user, include_unpubliced)
    wheres = ["blog_entries.visibility in (?)"]
    wheres << "blog_entries.visibility = ? AND blog_entries.user_id in (?)"
    wheres << "blog_entries.visibility = ? AND blog_entries.user_id = ?" if include_unpubliced
    where = wheres.map{|c| "(#{c})"}.join(" OR ")
    cond = [where,
            [BlogPreference::VISIBILITIES[:publiced],
             BlogPreference::VISIBILITIES[:member_only]],

            BlogPreference::VISIBILITIES[:friend_only],
            (user.friends.map(&:id) << user.id)]

    cond += [BlogPreference::VISIBILITIES[:unpubliced], user.id] if include_unpubliced
    return cond
  end

  # 指定されたRSSのURLは有効なものか？
  def self.valid_rss_url?(url)
    return true if attributes_by_rss_data(url)
    return false
  end

  protected
  # 生成時のデフォルト値設定
  def after_initialize
    self.blog_category_id ||= BlogCategory.default_category.id
  end

  private
  # 添付ファイルのサイズの合計値を検証
  def valid_total_filesize_of_attachments?
    tolta_size = blog_attachments.inject(0) do |total, ba|
      if ba.image.blank?
        total
      else
        total += File.size(ba.image) unless ba.image.blank?
      end
    end
    errors.add(:base, "ファイルの合計サイズが3MBを越えています")  if tolta_size && (tolta_size > 3.megabytes)
  end

  # 外部RSSのURLからエントリ作成
  def self.imported_entries_by_rss(url, user=nil)
    attrs = attributes_by_rss_data(url)
    if attrs
      return attrs.map do |attr|
        new(attr.merge(:user => user))
      end
    else
      logger.error("ERROR: 外部RSSの取り込みに失敗しました。 URL = #{url}")
      return []
    end
  end

  # 外部RSSからブログ記事に必要な情報取りだし
  def self.attributes_by_rss_data(url)
    res = []
    rss_data = open(url).read
    rss = RSS::Parser.parse(rss_data, false)
    case rss
    when RSS::Atom::Feed
      root = REXML::Document.new(rss_data).elements['feed']
      root.elements.each("entry") do |e|
        title = e.elements['title'].text.strip
        link = e.elements['link[@rel="alternate"]'].attributes['href']
        unless title.blank?
          res << {
            :title => title,
            :body => atom_entry_content_text(e.elements['content']),
            :created_at => atom_entry_date(e),
            :imported_by_rss => true,
            :url_to_article => link,
            :rss_title => rss.title.content,
            :rss_url => rss.link.href}
        end
      end
    when RSS::RDF, RSS::Rss
      rss.items.each do |i|
        unless i.title.blank?
          res << {
            :title => i.title,
            :body => i.description,
            :created_at => i.date.to_s,
            :imported_by_rss => true,
            :url_to_article => i.link,
            :rss_title => rss.channel.title,
            :rss_url => rss.channel.link}
        end
      end.compact
    else
      raise "正しいRSSとしてパースできませんでした。"
    end
    res.each do |r|
      raise "RSSからタイトル、日付が取得できませんでした" if r[:title].blank? || r[:created_at].blank?
    end
    return res
  rescue Exception => ex
    # NOTE: 外部RSSのパース失敗時のExceptionは無視して、失敗したことだけをユーザに伝える。
    Rails.logger.error{ "外部RSSのパースエラー: #{ex.class} : #{ex.message} URL : #{url}" }
    return false
  end

  # Atomエントリ内のコンテント取得
  def self.atom_entry_content_text(entry)
    type = entry.attributes['type']
    mode = entry.attributes['mode']

    if type == 'xhtml' || mode == 'xml'
      entry = entry.elements["div"].nil? ? entry : entry.elements["div"]
      res = entry.children.to_s
    else
      if entry.cdatas.size > 0
        res = entry.cdatas.to_s
      else
        res = entry.text
      end
      if type == 'html' || mode == 'escaped'
        res = CGI::unescapeHTML(res)
      end
    end
    return res.strip
  end

  # Atomエントリ内の日付取得
  def self.atom_entry_date(entry)
    %w(published issued updated created).each do |i|
      return entry.elements[i].text if entry.elements[i]
    end
    nil
  end
end

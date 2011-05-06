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

class CommunityThread < ActiveRecord::Base
  belongs_to :community
  belongs_to :author, :foreign_key => "user_id", :class_name => "User"
  has_many :replies, :class_name => "CommunityReply", :order => "created_at desc",
           :foreign_key => "thread_id", :dependent => :destroy
  has_many :active_replies, :class_name => "CommunityReply", :order => "created_at desc",
           :foreign_key => "thread_id", :conditions => {:deleted => false}
  has_many :attachments, :class_name => "CommunityThreadAttachment", :foreign_key => "thread_id",
           :order => "position desc", :dependent => :destroy
  accepts_nested_attributes_for :attachments, :allow_destroy => true

  before_create :set_lastposted_at
  after_create :save_community_lastposted_at
  after_create :notify_comment

  # イベント数、マーカー数、トピック数のカウントを設定
  after_save :update_count
  after_destroy :update_count

  @@default_index_order = 'community_threads.created_at DESC'
  cattr_accessor :default_index_order

  named_scope :lastposts, lambda {
    {:order => "community_threads.lastposted_at DESC"}
  }

  # コミュニティが外部公開しているもののみを取得
  named_scope :by_publiced_community, lambda {
    { :conditions => ["communities.visibility = ?", Community::VISIBILITIES[:public]],
      :include => :community}
  }

  validate :valid_total_filesize_of_attachments?

  def kind
    self[:type]
  end

  def kind=(type)
    self[:type] = type
  end

  def sorted_attachments
    self.attachments.sort_by{|a| a.position}
  end

  # フォーム添付ファイル生成
  def build_attachments
    3.times do |i|
      attachment = self.attachments.detect{|a| i+1 == a.position}
      if attachment.nil?
        self.attachments.build(:position => i+1)
      elsif !self.attachments[i].new_record? && self.attachments[i].image_changed?
        # NOTE: 確認画面からバリデーション失敗で戻ってきた時に画像パスをクリアするため
        self.attachments[i] = CommunityThreadAttachment.find(self.attachments[i].id)
      end
    end
  end

  # 地図を表示可能か？
  def map_viewable?
    !(latitude.nil? || longitude.nil? || zoom.nil?)
  end

  # スレッドごとにURLが異なるので、それぞれのクラスに該当するURLを作成する
  def polymorphic_url_on_community(view, options={})
    class_name = self.kind.underscore
    action = options[:action] ? options.delete(:action) : nil
    named_route = [action, class_name, "url"].compact.join("_")
    view.send(named_route, options.merge(:id => self.id, :community_id => self.community_id))
  end

  # 書き込みがあった場合、通知を受け取る設定にしている人にメール通知を行う
  # ただし、自分自身には送らない
  def notify_comment
    receivers = self.community.comment_notice_acceptable_members
    receivers.each do |r|
      CommentPostedNotifier.deliver_notice_comment(self, r) if self.author.id != r.id
    end

    receivers = self.community.comment_notice_acceptable_members_for_mobile
    receivers.each do |r|
      CommentPostedNotifier.deliver_notice_comment(self, r, true) if self.author.id != r.id
    end
  end

  # 編集できるかどうか
  def editable?(current_user)
    return false unless current_user
    self.author.id == current_user.id || self.community.admin?(current_user) || self.community.sub_admin?(current_user)
  end

  # 削除できるかどうか
  # 編集と条件が同じなので別名をつける
  alias :destroyable? :editable?

  # 作成者かどうかを返す
  def author?(user)
    self.author.id == user.id
  end

  # 文字列からサブクラスを返す
  def self.class_by_type(type)
    if type
      type.classify.constantize
    else
      CommunityTopic
    end
  end

  private
  # 添付ファイルのサイズの合計値を検証
  def valid_total_filesize_of_attachments?
    tolta_size = attachments.inject(0) do |total, a|
      if a.image.blank?
        total
      else
        total += File.size(a.image) unless a.image.blank?
      end
    end

    errors.add(:base, "ファイルの合計サイズが2MBを越えています")  if tolta_size && (tolta_size > 2.megabytes)
  end

  def set_lastposted_at
    self.lastposted_at ||= Time.now
  end

  # 投稿されたとき、コミュニティのlastposted_atを更新する
  def save_community_lastposted_at
    self.community.update_attributes!(:lastposted_at => Time.now)
  end

  # イベント数、マーカー数、トピック数をそれぞれ更新する
  def update_count
    community.topics_count = community.topics.count
    community.events_count = community.events.count
    community.markers_count = community.markers.count
    community.save
  end
end

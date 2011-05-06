# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_replies
#
#  id           :integer         not null, primary key
#  thread_id    :integer
#  parent_id    :integer
#  title        :string(255)
#  content      :text
#  created_at   :datetime
#  updated_at   :datetime
#  user_id      :integer
#  community_id :integer
#  deleted      :boolean
#

class CommunityReply < ActiveRecord::Base
  belongs_to :thread, :class_name => "CommunityThread", :foreign_key => "thread_id"
  acts_as_tree :order => "created_at"
  belongs_to :author, :foreign_key => "user_id", :class_name => "User"
  belongs_to :community
  has_many :attachments, :class_name => "CommunityReplyAttachment",
           :order => "position desc", :dependent => :destroy

  accepts_nested_attributes_for :attachments, :allow_destroy => true

  @@presence_of_columns = [:title, :content]
  validates_presence_of @@presence_of_columns
  cattr_reader :presence_of_columns

  after_create :save_community_lastposted_at
  after_create :save_community_thread_lastposted_at
  after_create :notify_comment

  @@default_index_order = 'community_replies.created_at DESC'
  cattr_accessor :default_index_order

  validate :valid_total_filesize_of_attachments?

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
        self.attachments[i] = CommunityReplyAttachment.find(self.attachments[i].id)
      end
    end
  end

  # スレッドごとにURLが異なるので、それぞれのクラスに該当するURLを作成する
  def polymorphic_url_on_community(view, options={})
    class_name = thread.class.to_s.underscore
    action = options[:action] ? options.delete(:action) : nil
    named_route = [action, class_name, "reply", "url"].compact.join("_")
    id_name = class_name.singularize + "_id"
    view.send(named_route, options.merge(:id => self.id, id_name => thread.id))
  end

  def kind
    'CommunityReply'
  end

  # 返信作成者がイベントに参加していればメンバーから外す
  # 参加していなければ入れる
  def create_or_delete_event_member
    if self.thread.kind == "CommunityEvent"
      event = self.thread
      if event.participations?(self.author)
        event.cancel_participation(self.author)
      else
        event.participate_in(self.author)
      end
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

  # 新規作成時のデフォルトの件名
  def default_subject
    if self.new_record?
      if self.parent
        parent_title = self.parent.title
        case parent_title
        when /^Re: /
          "Re[2]: " + parent_title.gsub(/^Re: /, "")
        when /^Re\[(\d+)\]: /
          "Re[#{$1.to_i + 1}]: " + parent_title.gsub(/^Re\[(\d+)\]: /, "")
        else
          "Re: #{parent_title}"
        end
      else
        "Re: #{thread.try(:title)}"
      end
    else
      self.subject
    end
  end

  # 返信元のcontentを引用文として現在のcontentに含める
  def quote_content
    if self.parent
      comment = self.parent
    else
      comment = self.thread
    end
    quoted_content = "#{comment.author.name}さんの発言\n> " + comment.content.gsub("\n", "\n> ")
    unless content.blank?
      quoted_content.insert(0, self.content + "\n\n")
    end
   quoted_content
  end

  # 論理削除を行う
  def set_deleted_flag
    self.update_attribute(:deleted, true)
  end

  protected

  # デフォルト値設定
  def after_initialize
    self.title ||= self.default_subject
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

  # 返信されたとき、スレッドのlastposted_atを更新する
  def save_community_thread_lastposted_at
    self.thread.update_attributes!(:lastposted_at => Time.now)
  end

  # 返信されたとき、コミュニティのlastposted_atを更新する
  def save_community_lastposted_at
    self.community.update_attributes!(:lastposted_at => Time.now)
  end
end

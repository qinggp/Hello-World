# == Schema Information
# Schema version: 20100227074439
#
# Table name: blog_preferences
#
#  id                        :integer         not null, primary key
#  preference_id             :integer
#  visibility                :integer
#  title                     :string(255)
#  basic_color               :integer
#  comment_notice_acceptable :boolean
#  created_at                :datetime
#  updated_at                :datetime
#  email_post_visibility     :integer
#  rss_url                   :string(255)
#  wyswyg_editor             :boolean
#
#
# ユーザブログ設定
#
# ユーザ毎のブログの全体設定を保持します。
class BlogPreference < ActiveRecord::Base
  belongs_to :preference

  # 公開制限, 非公開or下書き(:unpubliced) トモダチのみ(:friend_only) メンバーのみ(:member_only) 公開(:publiced)
  enum_column :visibility, :unpubliced, :friend_only, :member_only, :publiced
  enum_column :email_post_visibility, VISIBILITIES
  enum_column :basic_color, :green, :blue, :orange, :brown

  validates_inclusion_of :visibility, :in => VISIBILITIES.values
  validates_inclusion_of :email_post_visibility, :in => VISIBILITIES.values
  validates_inclusion_of :basic_color, :in => BASIC_COLORS.values
  validates_presence_of :title
  validate :valid_rss_url?

  # 更新前処理
  def before_update
    if visibility_changed?
      # NOTE: 各公開制限の整合性をとる
      unless on_visibility_range?(email_post_visibility)
        self.email_post_visibility = self.visibility
      end
      BlogEntry.visibility_narrow_down(preference.user, self.visibility) if preference
    end
  end

  # コメント通知受け取り設定
  #
  # ==== 備考
  #
  # 送られてくる情報が文字列の"true","false"の為、それをbooleanに直しま
  # す。
  def comment_notice_acceptable=(value)
    self[:comment_notice_acceptable] = (value.to_s == "true")
  end

  # 匿名ユーザは閲覧可能か？
  def anonymous_viewable?
    visibility_publiced?
  end

  # SNSメンバは閲覧可能か？
  def member_viewable?
    visibility_publiced? || visibility_member_only?
  end

  # トモダチは閲覧可能か？
  def friend_viewable?
    visibility_publiced? || visibility_member_only? || visibility_friend_only?
  end

  # 選択可能な公開制限一覧返却
  def selectable_visibilities(choices=[])
    values = []
    sym_choices = choices.map(&:to_sym)
    VISIBILITIES.sort_by{|k, v| -v}.map do |k, v|
      if on_visibility_range?(v) && (choices.empty? || sym_choices.include?(k))
        values << [k, v]
      end
    end
    return values
  end

  # 指定された区分値はブログ公開範囲内であるか
  def on_visibility_range?(level)
    return false if self.visibility.nil?
    level <= self.visibility
  end

  # メール投稿の場合のコメント制限
  # メール投稿時のブログの公開範囲が外部公開であっても、コメント制限はメンバーのみに抑制する
  def comment_restraint_for_email
    return VISIBILITIES[:member_only] if self.email_post_visibility_publiced?
    self.email_post_visibility
  end

  protected

  # デフォルト値設定
  def after_initialize
    self.title ||= "#{preference.try(:user).try(:name)}のブログ"
    self.visibility ||=  VISIBILITIES[:friend_only]
    self.email_post_visibility ||= VISIBILITIES[:friend_only]
    self.basic_color ||= BASIC_COLORS[:green]
  end

  # 外部RSSは使用可能か？
  def valid_rss_url?
    if rss_url_changed? && !rss_url.blank? && !BlogEntry.valid_rss_url?(rss_url)
      errors.add(:rss_url, "は有効なRSSではありません。")
      return false
    end
    return true
  end
end

# == Schema Information
# Schema version: 20100227074439
#
# Table name: preferences
#
#  id                        :integer         not null, primary key
#  user_id                   :integer
#  home_layout_type          :integer
#  created_at                :datetime
#  updated_at                :datetime
#  skype_id                  :string(255)
#  skype_id_visibility       :integer
#  skype_mode                :integer
#  yahoo_id                  :string(255)
#  yahoo_id_visibility       :integer
#  message_notice_acceptable :boolean         default(TRUE)
#
#
# ユーザ設定
#
# それぞれのユーザの設定を保持。ユーザが作成される際に必ず生成され、紐付けられる。
#
# 拡張機能に関連する部分はXXXPreferenceというモデルを作成し、has_oneで
# 関連させている。
class Preference < ActiveRecord::Base
  belongs_to :user

  # 公開制限
  VISIBILITIES = {
    :friend_only => 1, # トモダチのみ
    :member_only => 2, # メンバーのみ
    :publiced    => 3, # 公開
  }.freeze

  enum_column :skype_id_visibility, Preference::VISIBILITIES
  enum_column :yahoo_id_visibility, Preference::VISIBILITIES
  enum_column :profile_restraint_type, :member => true, :public => false
  enum_column :home_layout_type, :default, :mixi
  enum_column :skype_mode, :call, :chat, :profile

  # 設定の関連名リスト
  @@preference_associations = []
  cattr_reader :preference_associations
  attr_protected :user_id

  validates_inclusion_of :home_layout_type, :in => HOME_LAYOUT_TYPES.values

  # ユーザ設定に紐付く設定の関連名を追加
  #
  # ==== 引数
  #
  # * name - 関連名
  def self.add_preference_associations(name)
    @@preference_associations << name
    @@preference_associations.uniq!
  end

  # 指定したメッセンジャーを見られるユーザか？
  def visible_messenger?(current_user, field_name)
    visibility = send(field_name.to_s + "_visibility")
    case visibility
    when VISIBILITIES[:publiced]
      return true
    when VISIBILITIES[:member_only]
      return !current_user.nil?
    when VISIBILITIES[:friend_only]
      return false if current_user.nil?
      return true if user.same_user?(current_user)
      return current_user.friend_user?(user)
    end
  end

  # 更新したデータか？
  def updated?
    self.created_at != self.updated_at
  end

  protected
  # 生成時のデフォルト値設定
  def after_initialize
    self.home_layout_type ||= HOME_LAYOUT_TYPES[:default]
    @@preference_associations.map(&:to_s).each do |name|
      send("#{name}=", name.classify.constantize.new(:preference => self)) if send(name).nil?
    end
  end
end

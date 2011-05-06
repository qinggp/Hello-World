# == Schema Information
# Schema version: 20100227074439
#
# Table name: invites
#
#  id                :integer         not null, primary key
#  email             :string(255)
#  user_id           :integer
#  body              :text
#  relation          :integer
#  contact_frequency :integer
#  state             :string(255)
#  private_token     :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#
# 招待
class Invite < ActiveRecord::Base
  belongs_to :user

  before_save :set_private_token

  @@default_index_order = "invites.created_at DESC"
  @@presence_of_columns = [:user_id, :email, :contact_frequency, :relation]
  cattr_accessor :default_index_order, :presence_of_columns
  attr_accessor :mail_sender_me
  attr_accessible :email, :body, :relation, :contact_frequency, :state, :mail_sender_me

  validates_presence_of @@presence_of_columns
  validates_uniqueness_of :email, :scope => :user_id
  validates_uniqueness_of :private_token
  validates_format_of :email, :with => Mars::EMAIL_REGEX, :message => Mars::BAD_EMAIL_MESSAGE

  enum_column :relation, Friendship::RELATIONS
  enum_column :contact_frequency, Friendship::CONTACT_FREQUENCIES

  # 送信元を自分のアドレスにするか？
  def mail_sender_me?
    !mail_sender_me.blank?
  end

  protected
  # 生成時のデフォルト値設定
  def after_initialize
    # NOTE: validates_uniqueness_ofでひっかかると、self.bodyでエラーが発生するため
    begin
      self.body ||= "あなたも#{SnsConfig.title}に参加してみませんか？"
    rescue
    end
  end

  private
  def set_private_token
    self.private_token = Digest::SHA1.hexdigest(user_id.to_s+email.to_s+Time.now.to_s)
  end
end

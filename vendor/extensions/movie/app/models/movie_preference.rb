# == Schema Information
# Schema version: 20100227074439
#
# Table name: movie_preferences
#
#  id                 :integer         not null, primary key
#  preference_id      :integer
#  default_visibility :integer
#  created_at         :datetime
#  updated_at         :datetime
#

class MoviePreference < ActiveRecord::Base
  belongs_to :preference

  # 公開制限
  VISIBILITIES = {
    :unpubliced  => 1, # 非公開or下書き
    :friend_only => 2, # トモダチのみ
    :member_only => 3, # メンバーのみ
    :publiced    => 4, # 公開
  }.freeze

  enum_column :default_visibility, VISIBILITIES

  validates_inclusion_of :default_visibility, :in => VISIBILITIES.values

  attr_accessible :default_visibility

  protected
  
  # デフォルト値設定
  def after_initialize
    self.default_visibility ||= VISIBILITIES[:friend_only]
  end
end

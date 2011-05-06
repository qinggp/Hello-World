# == Schema Information
# Schema version: 20100227074439
#
# Table name: information
#
#  id           :integer         not null, primary key
#  title        :text
#  content      :text
#  display_type :integer
#  display_link :integer
#  public_range :integer
#  created_at   :datetime
#  updated_at   :datetime
#  expire_date  :date
#

class Information < ActiveRecord::Base
  require 'date'

  @@default_index_order = 'information.created_at DESC'
  @@default_per_page = 5

  enum_column :display_link, :no_link, :link
  # 最新のお知らせ, 固定のお知らせ, 重要なお知らせ, 非公開
  enum_column :display_type, :new, :fixed, :important, :private
  # SNS内のみ, 外部も公開, 外部のみ公開
  enum_column :public_range, :sns_only, :published_externally, :external_only

  # 対象のユーザが閲覧可能なお知らせ一覧
  named_scope :by_viewable_for_user, lambda{|user|
    if user.nil?
      viewable_public_ranges = [PUBLIC_RANGES[:external_only],
                                PUBLIC_RANGES[:published_externally]]
    else
      viewable_public_ranges = [PUBLIC_RANGES[:sns_only],
                                PUBLIC_RANGES[:published_externally]]
    end
    {:conditions => ["public_range in (?) AND display_type != ?",
                     viewable_public_ranges,
                     DISPLAY_TYPES[:private]]}
  }

  # 表示期間内のお知らせ一覧
  named_scope :by_not_expire, lambda{
    {:conditions => ["expire_date >= ?", Date.today]}
  }

  validates_presence_of :title
  validates_presence_of :expire_date
  validates_inclusion_of :display_link, :in => DISPLAY_LINKS.values
  validates_inclusion_of :display_type, :in => DISPLAY_TYPES.values
  validates_inclusion_of :public_range, :in => PUBLIC_RANGES.values
  cattr_reader :default_index_order
end

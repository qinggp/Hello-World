# == Schema Information
# Schema version: 20100227074439
#
# Table name: blog_categories
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  shared     :boolean
#

class BlogCategory < ActiveRecord::Base
  belongs_to :user
  has_many :blog_entries, :validate => false

  @@default_index_order = "blog_categories.created_at ASC"
  @@wom_id = 2
  @@default_category_id = 1
  cattr_accessor :default_index_order, :wom_id
  attr_accessible :name, :user

  validates_presence_of :name

  # 削除前処理
  def before_destroy
    self.blog_entries.each do |entry|
      entry.blog_category = self.class.default_category
      entry.save(false)
    end
  end

  # 標準カテゴリ返却
  def self.default_category
    return self.find(@@default_category_id)
  end
end

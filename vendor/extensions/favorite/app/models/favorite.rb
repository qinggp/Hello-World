# == Schema Information
# Schema version: 20100227074439
#
# Table name: favorites
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  name       :string(255)
#  url        :string(255)
#  category   :string(255)
#  created_at :datetime
#  updated_at :datetime
#
#
# お気に入り
class Favorite < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :name, :url, :category

  @@default_index_order = "created_at DESC"

  cattr_reader :default_index_order
  attr_accessible :name, :url, :category

  # 引数に取ったユーザの所有物か？
  def owner?(user)
    user_id == user.id
  end
end

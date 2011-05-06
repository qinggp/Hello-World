# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_categories
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  parent_id  :integer
#  created_at :datetime
#  updated_at :datetime
#

class CommunityCategory < ActiveRecord::Base
  acts_as_tree :order => "id"

  has_many :communities

  validates_presence_of :name

  # parent_idがnull、つまり親カテゴリのみ取得する
  def self.root
    self.find(:all, :conditions => "parent_id is null",
              :order => "id")
  end

  # 子にあたるノードを全て取得する
  # 現在親(root)-子の単純な関係なので、子の子、といったものは考慮しない
  def self.sub_categories
    root.map{ |r| r.children }.flatten
  end

  # カテゴリーの名前を親カテゴリとともに表示する
  # 親カテゴリであればそのまま表示
  def name_with_parent
    self.parent ? self.name + " (#{self.parent.name}) " : self.name
  end
end

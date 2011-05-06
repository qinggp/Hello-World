# == Schema Information
# Schema version: 20100227074439
#
# Table name: jobs
#
#  id       :integer         not null, primary key
#  name     :string(255)
#  position :string(255)
#

# 職業のDBマスターデータ
class Job < ActiveRecord::Base
  # Viewに渡すセレクトボックスのオプション
  def self.select_options
    self.find(:all, :select => "id,name",:order => "position ASC").map{|r| [r.name, r.id]}
  end
end

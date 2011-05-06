# == Schema Information
# Schema version: 20100227074439
#
# Table name: hobbies
#
#  id       :integer         not null, primary key
#  name     :string(255)
#  position :integer
#

# 趣味のDBマスターデータ
class Hobby < ActiveRecord::Base
end

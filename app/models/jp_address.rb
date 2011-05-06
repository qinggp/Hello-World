# == Schema Information
# Schema version: 20100227074439
#
# Table name: jp_addresses
#
#  id            :integer         not null, primary key
#  prefecture_id :integer
#  zipcode       :string(255)
#  city          :string(255)
#  town          :string(255)
#
# 郵便番号と住所マッピングのDBマスターデータ
class JpAddress < ActiveRecord::Base
  belongs_to :prefecture

  # 郵便番号検索
  #
  # ==== 引数
  #
  # * zipcode - 郵便番号
  def self.search_by_zipcode(zipcode)
    return self.zipcode_is(zipcode.delete("-"))
  end
end

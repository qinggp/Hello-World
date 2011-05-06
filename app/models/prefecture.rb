# == Schema Information
# Schema version: 20100227074439
#
# Table name: prefectures
#
#  id       :integer         not null, primary key
#  name     :string(255)
#  position :integer
#
# 都道府県のDBマスターデータ
class Prefecture < ActiveRecord::Base
  # Viewに渡すセレクトボックスのオプション
  def self.select_options
    self.find(:all, :select => "id,name", :order => "position ASC").map{|r| [r.name, r.id]}
  end

  # 各都道府県のyahooの天気情報ページのurlを返す
  def yahoo_weather_url
    base_url = "http://weather.yahoo.co.jp/weather/jp/"
    if id == 1
      base_url + "hokkaido.html"
    else
      base_url + "#{id}/"
    end
  end
end

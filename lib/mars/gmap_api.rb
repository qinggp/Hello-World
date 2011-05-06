require "open-uri"

# GoogleMapAPI使用モジュール
module Mars::GmapApi

  # 住所から緯度経度を取得
  #
  # 参考サイト：http://d.hatena.ne.jp/samori/20080211/1202745239
  class Geocode
    REQUEST_URL = "http://maps.google.com/maps/geo"
    VERSION = "2"

    attr_reader :lat
    attr_reader :lng
    attr_reader :result

    # 初期化
    #
    # ==== 引数
    #
    # * address - 住所（例：東京都など）
    def initialize(api_key, address)
      @url = "#{REQUEST_URL}?&q=#{CGI.escape(NKF.nkf("-w -m0",address))}"+
        "&output=xml&key=#{api_key}"
      doc = REXML::Document.new(open(@url))
      if doc.elements["/kml/Response/Status/code"].text != "200"
        @result = false
        return
      end
      point = doc.elements["/kml/Response/Placemark/Point/coordinates"].text.split(/,/)
      @lng = point[0]
      @lat = point[1]
      @result = true
    end
  end

  # 静的地図のURL出力
  #
  # 参考サイト：http://d.hatena.ne.jp/zegenvs/20080224/p1
  class StaticMap
    REQUEST_URL = 'http://maps.google.com/staticmap'
    VERSION = "2"

    # マーカリスト
    #
    # 配列内にはハッシュを入れる。詳細は以下。
    # * marker[:latitude] - 緯度
    # * marker[:longitude] - 経度
    # * marker[:color] - マーカの色
    # * marker[:label] - マーカ内に表示する文字
    # * marker[:size] - マーカサイズ（tiny,mid,small)
    attr_accessor :markers, :latitude, :longitude, :zoom

    # 初期化
    #
    # ==== 引数
    #
    # * api_key
    # * latitude
    # * longitude
    # * settings[:zoom]
    # * settings[:width] - マップの幅（512まで）
    # * settings[:height] - 高さ（512まで）
    # * settings[:type] - タイプ(roadmap,satellite,terrain,hybrid)
    # * settings[:mobile] - 携帯用表示(true/false)
    # * settings[:hl] - 言語
    # * settings[:span] - 表示範囲
    def initialize(api_key, latitude, longitude, settings = {}, markers = [])

      raise ArgumentError.new('latitude mast be found')  unless latitude
      raise ArgumentError.new('longitude mast be found') unless longitude

      @query = ''
      @query = REQUEST_URL + "?center=#{latitude.to_f},#{longitude.to_f}"

      settings = settings.with_indifferent_access
      settings[:width] = (1..512).include?(settings[:width].to_i) ? settings[:width].to_i : 256
      settings[:height] = (1..512).include?(settings[:height].to_i) ? settings[:height].to_i : 256
      settings[:zoom] = (settings[:zoom].to_i <=  0 ) ? 0 : settings[:zoom].to_i
      settings[:type] ||= 'roadmap'
      settings[:hl] ||= 'ja'
      settings[:mobile] = true if settings[:mobile].nil?

      @query += "&size=#{settings[:width]}x#{settings[:height]}"
      @query += "&zoom=#{settings[:zoom]}" if settings[:span].blank?
      %w(span type mobile hl).each do |key|
        @query += "&#{key}=#{settings[key]}"unless settings[key].blank?
      end
      @query += "&key=#{api_key}"

      @markers = markers
      @latitude = latitude
      @longitude = longitude
      @zoom = settings[:zoom]
    end

    # マーカのクエリ生成
    def marker_query
      querys = []
      self.markers.each do |marker|
        marker = marker.with_indifferent_access
        next if not marker[:latitude] or not marker[:longitude]
        str = ""
        opts = []
        str << [marker[:latitude], marker[:longitude]].join(",")
        %w(size color label).each do |key|
          opts << marker[key].downcase if !marker[key].blank?
        end
        querys << [str, opts.join("")].join(",")
      end
      return nil if querys.empty?
      return  "markers="+ querys.join("|")
    end

    def to_s
      [@query, marker_query].join("&")
    end
  end
end

require 'rss/2.0'
require 'open-uri'

module Mars::SnsLinkage

  # SNS連携情報（RSS）を扱う
  class RssParser

    # RSSをパース＆キャッシュ
    def self.parse(url)
      return RSS::Parser.parse(read_rss(url), false)
    rescue Exception => ex
      Rails.logger.error{ "ERROR: #{ex.class} : #{ex.message}" }
      return nil
    end

    private
    # RSSデータ読み込み
    def self.read_rss(url)
      open(url) do |http|
        return http.read
      end
    end
  end
end

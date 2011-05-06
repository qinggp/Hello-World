# SNS連携APIヘルパ
module SnsLinkageApiHelper
  def sns_logo_url
    return "http://#{request.host_with_port}/#{theme_image_path('sns_linkage/linkage_logo.gif')}"
  end

  def sns_api_rss2_feed_layout(xml, &block)
    xml.rss("version" => "2.0") do
      xml.channel do
        xml.title SnsConfig.title
        xml.link root_url
        xml.description SnsConfig.title
        xml.language "ja"
        xml.pubDate Time.now.rfc822
        xml.copyright Mars::COPY_RIGHT
        xml.image do
          xml.url sns_logo_url
          xml.title SnsConfig.title
          xml.link root_url
        end
        block.call(xml)
      end
    end
    xml
  end
end

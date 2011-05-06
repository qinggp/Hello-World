# Googleマップで地図内の位置選択を可能にします
module Mars::GmapSelectable

  # PC版
  #
  # _init.html.erbに
  #   <%= javascript_include_tag "gmap_selector" %>
  # を追加してください。
  module PC
    def self.included(klass)
      klass.send(:include, InstanceMethods)
    end

    module InstanceMethods
      # 座標設定用の地図を開く
      def select_map
        keys = %w(latitude longitude zoom)
        if keys.any?{|k| params[k].blank? }
          @latitude = SnsConfig.g_map_latitude
          @longitude = SnsConfig.g_map_longitude
          @zoom = SnsConfig.g_map_zoom
        else
          keys.each do |k|
            instance_variable_set("@#{k}", params[k])
          end
        end
        # レイアウトは不要
        render '/share/select_map', :layout => false
      end
    end
  end

  # 携帯版
  module Mobile
    def self.included(klass)
      klass.send(:include, InstanceMethods)
      klass.class_eval {
        helper_method :search_address_request_for_mobile?
        helper Mars::GmapSelectable::Mobile::Helper
      }
    end

    module InstanceMethods

      # 住所検索を行うリクエストか？
      #
      # ==== 引数
      #
      # * params[:search_address]
      def search_address_request_for_mobile?
        (params.has_key?(:search_address) || params.has_key?(:clear_address)) && request.mobile?
      end
    end

    module Helper

      # 静的GoogleMap返却
      # 
      # ==== 引数
      #
      # * address - 住所
      # * zoom - ズーム
      def static_map_by_address_for_mobile(address, zoom)
        map = nil
        return nil if address.blank?
        geo = Mars::GmapApi::Geocode.new(SnsConfig.g_map_api_key, address)
        if geo.result
          map = static_map_for_mobile(geo.lat,
                                      geo.lng,
                                      zoom)
        end
        return map
      end

      # 静的GoogleMap返却
      # 
      # ==== 引数
      #
      # * latitude
      # * longitude
      # * zoom
      def static_map_for_mobile(latitude, longitude, zoom)
        return nil if latitude.blank? || longitude.blank? || zoom.blank?
        map =  Mars::GmapApi::StaticMap.new(SnsConfig.g_map_api_key,
                                            latitude,
                                            longitude,
                                            :zoom => zoom)
        map.markers << {:latitude => latitude, :longitude => longitude, :color => "red"}
        return map
      end

      # ズーム選択オプション
      def zoom_select_options
        (0..19).map{|i| [i.to_s, i]}
      end
    end
  end
end

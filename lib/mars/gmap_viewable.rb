# Googleマップ表示
module Mars::GmapViewable

  # Googleマップ表示携帯用
  module Mobile
    DEFAULT_SPAN_LAT = 0.01
    DEFAULT_SPAN_LNG = 0.01
    DEFAULT_SPAN = "#{DEFAULT_SPAN_LAT},#{DEFAULT_SPAN_LNG}"

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval {
        helper Mars::GmapViewable::Mobile::Helper
      }
    end

    module InstanceMethods
      # 携帯用マップ表示アクション
      def map_for_mobile
        raise NotImplementedError
      end

      private
      # 携帯用マップ表示に必要なパラメータを設定
      def set_map_for_mobile_params
        @latitude = params[:latitude].to_f
        @longitude = params[:longitude].to_f
        @span_lat = params[:span_lat].to_f
        @span_lng = params[:span_lat].to_f
        offset = (@span_lat/2)
        @longitude_start = @longitude - offset
        @longitude_end = @longitude + offset
        # NOTE: 緯度は南に行くほど小さい数字となる
        @latitude_start = @latitude - offset
        @latitude_end = @latitude + offset
      end
    end

    module Helper

      # 静的GoogleMap返却
      #
      # ==== 引数
      #
      # * records - レコード
      # * latitude
      # * longitude
      # * zoom
      def static_map_for_records(records, latitude, longitude, span_lat, span_lng)
        return nil if latitude.blank? || longitude.blank? || span_lat.blank? || span_lng.blank?
        span = "#{span_lat},#{span_lng}"
        map =  Mars::GmapApi::StaticMap.new(SnsConfig.g_map_api_key,
                                            latitude,
                                            longitude,
                                            :span => span)
        label = "a"
        records.each do |record|
          map.markers << {:latitude => record.latitude, :longitude => record.longitude, :color => "red", :label => label.dup}
          label.succ!
        end
        return map
      end

      # マップの移動リンク生成
      def link_for_static_map_direction(label, direction, latitude, longitude, span_lat, span_lng, url_options={})
        case direction
        when :up
          latitude += span_lat
        when :down
          latitude -= span_lat
        when :left
          longitude -= span_lng
        when :right
          longitude += span_lng
        end
        link_to(label, url_options.merge(:action => :map_for_mobile, :latitude => latitude,
                :longitude => longitude, :span_lat => span_lat, :span_lng => span_lng))
      end

      # マップの移動リンク生成
      def link_for_static_map_zoom(label, type, latitude, longitude, span_lat, span_lng, url_options)
        case type
        when :in
          span_lat = span_lat / 2
          span_lng = span_lng / 2
        when :out
          span_lat = span_lat * 2
          span_lng = span_lng * 2
        end
        link_to(label, url_options.merge(:action => :map_for_mobile, :latitude => latitude,
                :longitude => longitude, :span_lat => span_lat, :span_lng => span_lng))
      end
    end
  end
end

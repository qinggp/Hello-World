module Mars::Movie::ModelExtension
  module Preference
    def self.included(base)
      base.class_eval {
        has_one :movie_preference, :autosave => true, :dependent => :destroy

        accepts_nested_attributes_for :movie_preference

        # ユーザ動画設定の関連追加
        self.add_preference_associations :movie_preference
      }
    end
  end

  module User
    def self.included(base)
      base.class_eval {
        has_many :movies, :order => "movies.created_at DESC", :dependent => :destroy

        # ユーザの動画ディスク使用量を取得する
        #
        # バイト単位で動画ファイルとしてのディスク使用量を返却する
        # 加算対象ファイルは以下のファイルとする
        # * 未変換オリジナルファイル
        # * 変換済みの FLV, 3GP, 3G2 ファイル
        # * サムネイル画像
        def movies_size
          total_size = movies.inject(0) do |size, movie|
            case movie.convert_status
            when Movie::CONVERT_STATUSES[:yet], Movie::CONVERT_STATUSES[:error]
              size += File.size(movie.original_file_path) if movie.original_file_path
            when Movie::CONVERT_STATUSES[:done]
              %w(flv 3gp 3g2).each do |type|
                size += File.size(movie.file_path(type)) if movie.file_path(type)
              end
              [:mobile, :pc].each do |type|
                if movie.thumbnail_file_path(type)
                  size += File.size(movie.thumbnail_file_path(type))
                end
              end
            end
            next size
          end

          return total_size
        end

        # 現在アップロードが許可されているサイズ
        def remaining_disk_size
          max_size = Mars::Movie::ResourceLoader['application']['movie_limited_size'].to_i
          return (max_size - movies_size > 0 ? max_size - movies_size : 0)
        end

        # ユーザが動画アップロード可能かどうかを判定する
        def movie_uploadable?
          return true unless Mars::Movie::ResourceLoader['application']['movie_limited']
          return !remaining_disk_size.zero?
        end
      }
    end
  end
end

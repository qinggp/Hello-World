# 非公開の画像ファイル表示モジュール
#
# include 後 unpublic_image_accessible メソッドを使用
module Mars::UnpublicImageAccessible
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.send(:helper, Mars::UnpublicImageAccessible::Helper)
  end

  module ClassMethods
    # 非公開の画像ファイル表示用メソッド定義
    #
    # ==== 引数
    #
    # * options[:modle_name] - 画像モデル名
    def unpublic_image_accessible(options)
      class_name = options[:model_name].to_s.classify
      instance_name = options[:model_name].to_s.underscore

      class_eval <<-EOV
        @@unpublic_image_classes ||= {}
        @@unpublic_image_classes.update("#{instance_name}" => #{class_name})

        cattr_accessor :unpublic_image_classes
      EOV
    end
  end

  module InstanceMethods
    # 非公開の画像ファイル表示アクション
    #
    # ==== 引数
    #
    # * params[:(model_name)_id] - 画像モデルのID
    def show_unpublic_image
      model_name = unpublic_image_classes.keys.detect{|v| params.key?("#{v}_id")}
      image_instance = unpublic_image_classes[model_name].find(params["#{model_name}_id"])

      if image_instance.image =~ Mars::IMAGE_EXT_REGEX
        type =
          case image_instance.image
          when  /.*\.gif$/i
            # gif
            "image/gif"
          when  /.*\.jpe?g$/i
            "image/jpeg"
            # jpg
          when /.*\.png$/i
            "image/png"
            # png
          else
            "image/jpeg"
          end
        x_send_file(image_instance.image(params[:image_type]),
                  :type => type,
                  :disposition => "inline",
                  :filename => "イメージ表示")
      else
        x_send_file(image_instance.image(params[:image_type]))
      end
    end

    # 非公開の画像ファイル表示アクション（一時ファイル用）
    #
    # ==== 引数
    #
    # * params[:image_temp] - 一時ファイルパス
    # * params[:model_name] - 画像モデル名（複数モデルを登録しているときは指定する）
    #
    # ==== 備考
    #
    # unpublic_image_uploader_key= でキーを適切に設定していない場合、ア
    # クセス認証に引っかかります。
    def show_unpublic_image_temp
      unless unpublic_image_uploader?(params[:image_temp])
        logger.debug{ "DEBUG(show_unpublic_image_temp): my_session[:unpublic_image_uploader_key] : #{my_session[:unpublic_image_uploader_key]}, params[:image_temp] : #{params[:image_temp]}" }
        raise Mars::AccessDenied
      end

      unless params[:model_name].blank?
        image_instance = unpublic_image_classes[params[:model_name]].new(:image_temp => params[:image_temp])
      else
        image_instance = unpublic_image_classes.values.first.new(:image_temp => params[:image_temp])
      end

      if image_instance.image =~ Mars::IMAGE_EXT_REGEX
        x_send_file(image_instance.image(params[:image_type]),
                  :type => 'image/jpeg',
                  :disposition => "inline",
                  :filename => "イメージ表示")
      else
        x_send_file(image_instance.image(params[:image_type]))
      end
    end

    # 非公開のフラッシュファイル表示アクション
    #
    # ==== 引数
    #
    # * params[:(model_name)_id] - 画像モデルのID
    def show_unpublic_flash
      image_instance = unpublic_image_class.find(params["#{unpublic_image_model
_name}_id"])
      if image_instance.image =~ /.*\.(swf)$/
        x_send_file(image_instance.image(params[:image_type]),
                  :disposition => "inline")
      else
        x_send_file(image_instance.image(params[:image_type]))
      end
    end

    private
    # ファイルアップロード者を識別するためのキー設定
    def unpublic_image_uploader_key=(image_temp)
      my_session[:unpublic_image_uploader_key] ||= []
      my_session[:unpublic_image_uploader_key] << image_temp
    end

    # ファイルアップロード者か？
    def unpublic_image_uploader?(image_temp)
      return my_session[:unpublic_image_uploader_key].try(:include?, image_temp)
    end

    # キークリア
    def clear_unpublic_image_uploader_key
      my_session[:unpublic_image_uploader_key] = []
    end
  end

  module Helper
    # 画像、またはそれ以外のファイルを表示する
    # 画像ファイルは、画像のみを表示し、画像以外のファイルは、アイコン+ファイル名を表示し、リンクを張る
    # ただし、フォームで使用する場合は、画像にもアイコン+ファイル名を表示し、リンクを張る
    # また、携帯の場合は画像ファイルのみを表示する
    #
    # ==== 引数
    # * attachment: file_columnを使用しているオブジェクト
    # * options
    # * <tt>:image_type</tt> - 画像のタイプ
    # * <tt>:form</tt> - formで使用するかどうか
    # * <tt>:original_attachment_path</tt> - オリジナルファイルURL（指定しなくてもよい）
    # * <tt>:attachment_path</tt> - イメージ表示するファイルURL（指定なくてもよい）
    def display_attachment_file(attachment, options={})
      html = ""
      model_name = attachment.class.to_s.underscore
      attachment_path = ""
      original_attachment_path = ""

      if options[:original_attachment_path] && options[:attachment_path]
        original_attachment_path = options[:original_attachment_path]
        attachment_path = options[:attachment_path]
      else
        with_options(:action => :show_unpublic_image,
                     :id => params[:id],
                     "#{model_name}_id".to_sym => attachment.id) do |opt|
          attachment_path = opt.url_for(:image_type => options[:image_type])

          original_attachment_path = opt.url_for
        end
      end

      # 携帯の場合は、画像のみ表示する
      if request.mobile? && attachment.image =~ Mars::IMAGE_EXT_REGEX
        html << link_to(theme_image_tag(attachment_path, :hspace => 3, :vspace => 5, :style => "border: none;"), original_attachment_path, :popup => true)
        return html
      end

      # 画像以外、またはフォームで使用する場合は、アイコンとファイル名をリンク表示する
      if !(attachment.image =~ Mars::IMAGE_EXT_REGEX) || options[:form]
        html << theme_image_tag(icon_name_by_extname(attachment.image))
        file_name = File.basename(attachment.image)
        html << link_to(h(file_name), original_attachment_path)
      end

      # 画像を表示する
      if attachment.image =~ Mars::IMAGE_EXT_REGEX
        html << "<br />" unless html.blank?
        html << link_to(theme_image_tag(attachment_path, :hspace => 3), original_attachment_path)
      end

      html
    end

    # 仮ファイルを表示する
    # 画像は、アイコン+ファイル名と、画像自体も表示する。
    # また、その画像には元の大きい画像へのリンクを埋め込む
    # 画像以外のファイルは、アイコン+ファイル名のみを表示する
    #
    # ==== 引数
    # * attachment: file_columnを使用しているオブジェクト
    # * options
    # * <tt>:image_type</tt> - 画像のタイプ
    # * <tt>:original_attachment_path</tt> - オリジナルファイルURL（指定しなくてもよい）
    # * <tt>:attachment_path</tt> - イメージ表示するファイルURL（指定なくてもよい）
    # * <tt>:model_name</tt> - 画像モデル名。複数登録しているとき必要
    def display_temp_attachment_file(attachment, options={})
      html = ""
      model_name = attachment.class.to_s.underscore
      attachment_path = ""
      original_attachment_path = ""

      html << theme_image_tag(icon_name_by_extname(attachment.image_temp))
      html << h(File.basename(attachment.image_temp))

      if attachment.image_temp =~ Mars::IMAGE_EXT_REGEX
        if options[:original_attachment_path] && options[:attachment_path]
          original_attachment_path = options[:original_attachment_path]
          attachment_path = options[:attachment_path]
        else
          with_options(:action => :show_unpublic_image_temp,
                       :model_name => options[:model_name],
                       :image_temp => attachment.image_temp) do |opt|
            attachment_path = opt.url_for(:image_type => options[:image_type])

            original_attachment_path = opt.url_for
          end
        end
        html << "<br />"
        html << link_to(theme_image_tag(attachment_path),
                        original_attachment_path)
      end
      html
    end
  end
end

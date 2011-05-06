# バナー管理ヘルパ
module Admin::BannersHelper
  include Mars::Community::CommonHelper
  # 登録／更新画面のFrom情報生成
  def form_params
    if @banner
      if @banner.new_record?
        {:url => confirm_before_create_admin_banners_path,
          :model_instance => @banner, :multipart => true
          }
      else
        {:url => confirm_before_update_admin_banners_path(:id => @banner.id),
          :model_instance => @banner, :multipart => true

          }
      end
    end
  end


  def confirm_form_params
    if @banner.new_record?
      {:url => admin_banners_path, :method => :post,
        :model_instance => @banner}
    else
      {:url => admin_banner_path(@banner), :method => :put,
        :model_instance => @banner}
    end
  end

  # 一覧画面での表示期間を成形して返す
  def get_expire_date(banner)
    duration = banner.created_at.strftime('%y/%m/%d').to_s
    duration += "〜"
    duration += banner.expire_date.strftime('%y/%m/%d').to_s
    duration += "まで"
  end


  # バナーをソートするためのリンクパラメータの生成
  # kind: ソート対象を表す数字
  def parameter_for_order_link(kind)
    figure = ""
    asc_or_desc = Admin::BannersController::DESC

    if params[:order] && params[:order][:kind].to_i == kind
      # 現在のソート対象と一致しているとき
      case params[:order][:asc_or_desc].to_i
      when Admin::BannersController::ASC
        figure =  "▲"
        asc_or_desc = Admin::BannersController::DESC
      when Admin::BannersController::DESC
        figure = "▼"
        asc_or_desc = Admin::BannersController::ASC
      else
        figure = "▼"
        asc_or_desc = Admin::BannersController::ASC
      end
    elsif !params[:order] && kind.to_i == Admin::BannersController::CREATED_AT
      # デフォルトのソート
      figure = "▼"
      asc_or_desc = asc_or_desc = Admin::BannersController::ASC
    end

    order_parameter = {:order => {:kind => kind, :asc_or_desc => asc_or_desc}}

    yield(order_parameter) if block_given?
    concat figure unless figure.blank?
  end

  # バナー登録確認画面の添付画像表示
  def admin_confirm_banner_image(banner)
    image_link, image, update_message = "", "", ""

    # 更新時に、画像がどう変化したか
    unless banner.new_record?
      if banner.image?
        if banner.image_changed?
          update_message = "(修正)"
        else
          update_message = "(修正無し)"
        end
      end
    end
    image_link << theme_image_tag(icon_name_by_extname(banner.image))
    image_link << h(File.basename(banner.image))
    #  .gifファイルか
    if File.extname(banner.image) == ".gif"
      if banner.new_record? || banner.image_changed?
        image << admin_temp_banner_image(banner.image_temp)
      elsif !banner.image_changed?
        image << admin_banner_image(banner)
      end
      image_link + update_message + "<br />" + image
    else
    #  .swfファイルの場合
      image_link + update_message
    end
  end

  # バナーの仮の画像（小さいの）と元画像へのリンク
  def admin_temp_banner_image(image_temp, image_type = "medium")
    link_to(theme_image_tag(show_unpublic_image_temp_admin_banners_path(:image_temp => image_temp, :image_type => image_type)),
            show_unpublic_image_temp_admin_banners_path(:image_temp => image_temp))
  end

  # バナーの画像（小さいの）と元画像へのリンク
  def admin_banner_image(banner, image_type = "medium")
    link_to(theme_image_tag(show_unpublic_image_admin_banner_path(:banner_id => banner.id, :id => banner.id, :image_type => image_type)),
            show_unpublic_image_admin_banner_path(:banner_id => banner.id, :id => banner.id))
  end

  # バナー変更画面での画像の表示
  def admin_form_attachment_file(banner)
    case File.extname(banner.image)
    when ".gif"
      display_attachment_file(banner,
      :attachment_path =>
        show_unpublic_image_admin_banner_path(:banner_id => banner.id, :id => banner.id, :image_type => "medium"),
      :original_attachment_path =>
        show_unpublic_image_admin_banner_path(:banner_id => banner.id, :id => banner.id))
    when ".swf"
    end
  end


  # 変更画面でアイコンとファイル名を返す
  def show_edit_form_banner(banner)
    case File.extname(banner.image)
    when ".gif"
      file_path = show_unpublic_image_admin_banner_path(:id => banner.id, :banner_id => banner.id)
    when ".swf"
      file_path = show_unpublic_flash_admin_banner_path(:id => banner.id, :banner_id => banner.id)
    end
    link_name = theme_image_tag(icon_name_by_extname(banner.image))
    link_name << h(File.basename(banner.image))
    link = link_to(link_name, file_path)
    link
  end

    # バナー一覧画面での.gif .swfファイルの表示
  def images_banner_list_view(banner)
    html = ""
    case File.extname(banner.image)
    when ".gif"
      attachment_path =
        show_unpublic_image_admin_banner_path(:banner_id => banner.id, :id => banner.id, :image_type => "medium")
      html << theme_image_tag(attachment_path, {:alt => banner.comment})
    when ".swf"
      file_path = show_unpublic_flash_admin_banner_path(:banner_id => banner.id, :id => banner.id)
      swf_tag = making_flash_tag(file_path)
      html = swf_tag
    end
    return html
  end

private
  # フラッシュ画像を表示するタグを生成する
  def making_flash_tag(file_path)
    swf_tag = content_tag(:object, '', :data => file_path, :type => "application/x-shockwave-flash", :width => "300", :height => "60", :bgcolor => "#FFFFFF" ) do
      object = content_tag(:param, '', :name => "movie", :value => file_path)
      object << content_tag(:param, '', :name => "quality", :value => "high")
      object << content_tag(:param, '', :name => "wmode", :value => "transparent")
      object <<  content_tag(:embed, '',:src => file_path,
                            :quality => "high", :type => "application/x-shockwave-flash",
                            :width => 300, :height => 60, :wmode => "transparent", :bgcolor => "#FFFFFF")
      object
    end
    swf_tag
  end
  
end

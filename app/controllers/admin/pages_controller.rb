# 静的ページ管理（管理側）
class Admin::PagesController < Admin::ApplicationController
include Mars::UnpublicImageAccessible
  # 画像管理での画像ファイルのパス
  IMAGE_MANAGEMENT_PATH = File.join(Rails.public_path, "images")
  THEME_IMAGE_MANAGEMENT_PATH = File.join(Rails.public_path, "themes",
                                          SnsConfig.master_record.try(:sns_theme).try(:name).to_s,
                                          "images")

  # 画像の一覧表示画面での表示サイズ
  IMAGE_SIZE = '100x100'

  # ソート対象を表す定数
  PAGE_ID = 1
  TITLE = 2

  with_options :redirect_to => :admin_pages_url do |con|
    con.verify :params => "id", :only => %w(confirm_before_update)
    con.verify :params => "page",
      :only => %w(confirm_before_update update)
    con.verify :params => "upload", :only => %w(image_upload)
    con.verify :params => "filename", :only => %w(image_destroy)
    con.verify :method => :post, :only => %w(confirm_before_update)
    con.verify :method => :put, :only => %w(update)
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    if params[:per_page] && params[:per_page].to_i == 0
      @paginated = false
    else
      @paginated = true
    end
    order = construct_sort_order
    if @paginated
      @pages =
        Page.paginate(:per_page => (params[:per_page] ? params[:per_page] : 5),
                      :page => params[:page],
                      :order => order)
    else
      @pages = Page.find(:all,:order => order)
    end
  end

  def show_public_image
  end

  # 画像管理一覧
  def image_management
    @images = []
    @images << Dir.glob("#{IMAGE_MANAGEMENT_PATH}/**/*.*")
    @images << Dir.glob("#{THEME_IMAGE_MANAGEMENT_PATH}/**/*.*")
    @images.flatten!.uniq!
    @images = @images.map{|n| n.gsub(Rails.public_path, "")}
  end

  # 画像の削除
  def image_destroy
    image_path = File.join(Rails.public_path, params[:filename])
    File.unlink(image_path) if params[:filename] && File.exist?(image_path)
    return redirect_to image_management_admin_pages_path
  end

  # 画像のアップロード
  def image_upload
    if params[:upload]
      file = params[:upload]
      error_message = Page.validate_upload_image(params[:upload])
      if error_message.blank?
        @filename = params[:upload_path]
        if File.exist?("#{Rails.public_path}/#{@filename}")
          if params[:overwrite]
            File.open("#{Rails.public_path}/#{@filename}","wb"){ |f| f.write(file.read) }
          end
        else
          File.open("#{Rails.public_path}/#{@filename}","wb"){ |f| f.write(file.read) }
        end
      else
        flash[:error] = error_message
      end
      return redirect_to image_management_admin_pages_path
    else
      return redirect_to image_management_admin_pages_path
    end
  end


  # 編集フォームの表示．
  def edit
    @page ||= Page.find(params[:id])
    render "form"
  end

  # 編集確認画面表示
  def confirm_before_update
    @page = Page.find(params[:id])
    @page.attributes = params[:page]
    return redirect_to edit_admin_page_path(@page) if params[:clear]

    if @page.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 更新データをDBに保存．
  def update
    @page = Page.find(params[:id])
    @page.attributes = params[:page]
    return render "form" if params[:cancel] || !@page.valid?

    Page.transaction do
      @page.save!
    end

    redirect_to complete_after_update_admin_page_path(@page)
  end
end

# 静的ページ管理ヘルパ
module Admin::PagesHelper

  VERBOTEN_TAGS = %w(form script applet embed object input)
  VERBOTEN_ATTRS = /^on/i


  # 確認画面のForm情報
  def form_params
    if @page
      {:url => confirm_before_update_admin_pages_path(:id => @page.id),
        :model_instance => @page}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
      {:url => admin_page_path(@page), :method => :put,
        :model_instance => @page}
  end

  # VERBOTEN_TAGSのタグのみエスケープを行う
  def text_escape(str)
    if str.index("<")
      tokenizer = HTML::Tokenizer.new(str)
      new_text = ""

      while token = tokenizer.next
        node = HTML::Node.parse(nil, 0, 0, token, false)
        new_text << case node
          when HTML::Tag
            if VERBOTEN_TAGS.include?(node.name)
              node.to_s.gsub(/</, "&lt;")
            else
              if node.closing != :close
                node.attributes.delete_if { |attr,v| attr =~ VERBOTEN_ATTRS }
                if node.attributes["href"] =~ /^javascript:/i
                  node.attributes.delete "href"
                end
              end
              node.to_s
            end
          else
            node.to_s.gsub(/</, "&lt;")
        end
      end

      str = new_text
    end
    str

  end

  # ファーム内での改行をhタグに置き換えず、<br />タグに変換
  def br(str)
    str.gsub(/\r\n|\r|\n/, "<br />")
  end

  # 画像管理画面で画像を表示する
  def image_management_file_view(image)
    link_to(theme_image_tag(image, :size => Admin::PagesController::IMAGE_SIZE, :alt => image), image)
  end
end

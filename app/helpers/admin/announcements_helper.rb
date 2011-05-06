module Admin::AnnouncementsHelper

  VERBOTEN_TAGS = %w(form script applet embed object input)
  VERBOTEN_ATTRS = /^on/i

  # 登録／更新画面のFrom情報生成
  def form_params
    if @announcement
      if @announcement.new_record?
        {:url => confirm_before_create_admin_announcements_path,
          :model_instance => @announcement}
      else
        {:url => confirm_before_update_admin_announcement_path(:id => @announcement.id),
          :model_instance => @announcement}
      end
    end
  end


  def confirm_form_params
    if @announcement.new_record?
      {:url => admin_announcements_path, :method => :post,
        :model_instance => @announcement}
    else
      {:url => admin_announcement_path(@announcement), :method => :put,
        :model_instance => @announcement}
    end
  end

  # ブログエントリ本文表示
  #
  # ==== 引数
  #
  # entry - ブログエントリレコード
  #
  # ==== 戻り値
  #
  # サニタイズ済み本文
  def display_announcement_entry_content(entry)
    return sanitize(entry.content, :tags => %w(b i u font hr PIC EXT)).untaint
  end

  # 一覧ソート用のリンクを生成する
  #
  # ==== 引数
  #
  # * label - ラベル名
  # * options
  # * html_options
  #
  # ==== 戻り値
  #
  # 一覧ソート用のリンク
  def link_for_sort_announcements(label, options = {}, sw_word = {})
    options.reverse_merge!(
      :controller => params[:controller],
      :action => params[:action],

      :order_important => params[:order_important],
      :order_modifier_important => params[:order_modifier_important] || "DESC",
      :per_page_important => params[:per_page_important],
      :select_page_important => params[:select_page_important],

      :order_new => params[:order_new],
      :order_modifier_new => params[:order_modifier_new] || "DESC",
      :per_page_new => params[:per_page_new],
      :select_page_new => params[:select_page_new],

      :order_fixed => params[:order_fixed],
      :order_modifier_fixed => params[:order_modifier_fixed] || "DESC"
    )

    icon = ""
    if ordering_column_announcements?(options,sw_word)
        options[sw_word[:order_modifier]], icon =
          (options[sw_word[:order_modifier]] == "DESC") ? %w(ASC ▼) : %w(DESC ▲)
    end
    link_to(label, options, :method => :get) + "#{icon}"
  end

  #お知らせ一覧でのparams[]のハッシュを返します
  # ==== 引数
  #
  # ==== 戻り値
  # * パラメーターハッシュ
  # 例:controller => params[:controller]
  def params_for_announcements_list()
    work = {
      :controller => params[:controller],
      :action => params[:action],

      :order_important => params[:order_important],
      :order_modifier_important => params[:order_modifier_important],
      :per_page_important => params[:per_page_important],
      :select_page_important => params[:select_page_important],

      :order_new => params[:order_new],
      :order_modifier_new => params[:order_modifier_new],
      :per_page_new => params[:per_page_new],
      :select_page_new => params[:select_page_new],

      :order_fixed => params[:order_fixed],
      :order_modifier_fixed => params[:order_modifier_fixed]
    }
    return work
  end

  #パラメーターのハッシュの入ったhidden fieldの配列を返します。
  # ==== 引数
  #
  # ==== 戻り値
  # * hidden fieldの配列
  # "<input id=\"hidden\" name=\"#{key}\" type=\"hidden\" value=\"#{value}\"\/>\n"
  # 例:controller => params[:controller]
  def hidden_field_for_per_page()
    hashs = params_for_announcements_list()
    html = Array.new
    hashs.each do |key,value|
      if !value.blank?
        html << "<input id=\"hidden\" name=\"#{key}\" type=\"hidden\" value=\"#{h(value)}\"\/>\n"
      end
    end
    return html
  end

  private

  def ordering_column_announcements?(options={}, sw_word = {})
    return true if params[sw_word[:order]] == options[sw_word[:order]]
    default_order = options[:default_order].to_s
    if params[sw_word[:order]].nil? && default_order.include?(options[sw_word[:order]])
      options[sw_word[:order_modifier]] = "DESC" if default_order.include?("DESC")
      options[sw_word[:order_modifier]] = "ASC" if default_order.include?("ASC")
      return true
    end
    return false
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
end

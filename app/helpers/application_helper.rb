module ApplicationHelper
  include Mars::MobileEmoticonHelper

  ::WillPaginate::ViewHelpers.pagination_options[:previous_label] = '&laquo; 前へ'
  ::WillPaginate::ViewHelpers.pagination_options[:next_label] = '次へ &raquo;'
  ::WillPaginate::ViewHelpers.pagination_options[:renderer] = 'Mars::WillPaginate::LinkRenderer'

  # ホーム画面等のニュースのフォーマットで表示
  def display_news_line_format(date, link, reporter)
    reporters = Array.wrap(reporter).map{ |r| "(#{r})" }.join(" ")
    "◇#{h(l(date, :format => "month_date"))}…#{link} <span class='name_link'>#{reporters}</span>"
  end

  # ホーム画面等のニュースのフォーマットで表示（携帯用）
  def display_news_line_format_mobile(date, link, reporter)
    reporters = Array.wrap(reporter).map{ |r| "(#{r})" }.join(" ")
    "[#{h(l(date, :format => "default_month_date"))}] #{link} #{reporters}"
  end

  # 角丸の<div>要素コンテンツを表示する
  #
  # ==== 引数
  # * options
  # * <tt>:white_bg</tt> - 白抜きにするか
  # * <tt>:color</tt> - divの色
  # * <tt>:color_class</tt> - divの色
  # * <tt>:width</tt> - 横幅
  # * <tt>:height</tt> - 高さ
  # * <tt>:top_only</tt> - 角丸を上部に限定するか
  # * <tt>:bottom_only</tt> - 角丸を下部に限定するか
  def display_round_box(options={})
    options[:white_bg] = true if options[:white_bg].nil?
    bg_style = "background-color: #{options[:color]};"
    height = "height: #{options[:height].to_s};"
    width = "width: #{options[:width].to_s};"
    color_class = options[:color_class] || "content_box_bg"

    concat %Q(<div class="content_box" style="#{width}">)

    unless options[:bottom_only]
      concat %Q(<div class="round">)
      4.times do |i|
        concat %Q(<div class="r#{i+1}" style="#{bg_style}">)
        concat %Q(<div class="#{color_class}" style="width:100%;height:100%;#{bg_style}"></div>)
        concat %Q(</div>)
      end
      concat %Q(</div>)
    end

    concat %Q(<div class="#{color_class}">)
    concat %Q(<div class="content_inner_box" style="#{bg_style} #{height}">)
    concat %Q(<div class="content_inner_bg" style="#{height} background-color: white;">) if options[:white_bg]
    yield if block_given?
    concat %Q(</div>) if options[:white_bg]
    concat %Q(</div>)
    concat %Q(</div>)

    unless options[:top_only]
      concat %Q(<div class="round">)
      4.times do |i|
        concat %Q(<div class="r#{4-i}" style="#{bg_style}">)
        concat %Q(<div class="#{color_class}" style="width:100%;height:100%;#{bg_style}"></div>)
        concat %Q(</div>)
      end
      concat %Q(</div>)
    end

    concat %Q(</div>)
  end

  # エスケープして、改行コードをbrタグに置き換える
  def hbr(str)
    str = h str
    str.gsub(/\r\n|\r|\n/, "<br />")
  end

  # 改行コードをbrタグに置き換える
  def br(str)
    str.gsub(/\r\n|\r|\n/, "<br />")
  end

  # 1ページ当りの表示件数を指定するセレクトボックスを表示する
  #
  # ==== 引数
  # * per_pages: 件数の配列
  # * options
  # * <tt>:all_pages</tt> - 全件表示を有効にするか
  # * <tt>:param_name</tt> - パラメータの名前
  # * <tt>:checked_value</tt> - デフォルトの選択値
  def select_per_page(per_pages = [], options = { })
    per_pages = per_pages.blank? ? [5, 10, 20, 50, 100] : per_pages
    param_name = options[:param_name] || :per_page
    all_pages = true if options[:all_pages].nil?

    list = per_pages.map do |page|
      ["#{page}件", page]
    end
    list << ["全件", Mars::ALL_PAGES] if all_pages

    if params[param_name].blank?
      if options[:checked_value]
        checked_value = options[:checked_value]
      elsif
        checked_value = per_pages.first
      end
    else
      checked_value = params[param_name]
    end

    select_tag(param_name, options_for_select(list, checked_value.to_i))
  end

  # 表示ページを指定するセレクトボックスを生成する
  #
  # ==== 引数
  # * total_pages: ページ数
  # * options
  # * <tt>:param_name</tt> - パラメータの名前
  def select_page(total_pages, options = { })
    param_name = options[:param_name] || :page
    list = (1..total_pages).map do |page_number|
      ["#{page_number}ページ", page_number]
    end

    if params[param_name].blank?
      checked_value = 1
    else
      checked_value = params[param_name].to_i
    end

    select_tag(param_name, options_for_select(list, checked_value))
  end

  # ユーザが一覧表示される際の各ユーザの画像と、名前
  #
  # ==== 引数
  # * user: Userモデルのオブジェクト
  # * options:
  # * <tt>:width</tt> - 画像の横幅
  # * <tt>:height</tt> - 画像の縦幅
  # * <tt>:friend_count</tt> - トモダチの数を表示するかどうか
  def user_image_on_list(user, options = { })
    options[:width] ||= 76
    options[:friend_count] = true if options[:friend_count]

    content_tag(:table) do
      table = ""
      table << content_tag(:tr) do
        content_tag(:td, :align => "center", :valign => "middle") do
          link_to(user_path(user)) do
            display_face_photo(user.face_photo, :width=> options[:width], :height => options[:height])
          end
        end
      end
      table << content_tag(:tr) do
        content_tag(:td, :align => "center") do
          link_to(user_path(user)) do
            if options[:friend_count]
              h "#{user.name}さん(#{user.friends.count})"
            else
              h "#{user.name}さん"
            end
          end
        end
      end
    end
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
  def link_for_sort(label, options = {}, html_options = {})
    options.reverse_merge!(
      :controller => params[:controller],
      :action => params[:action],
      :order_modifier => params[:order_modifier] || "DESC",
      :per_page => params[:per_page])

    icon = ""
    if ordering_column?(options)
        options[:order_modifier], icon =
          (options[:order_modifier] == "DESC") ? %w(ASC ▼) : %w(DESC ▲)
    end

    link_to(label, options, :method => :get) + "#{icon}"
  end

  # ページのタイトル表示
  def page_title
    return nil if @title_off
    title = @title
    full_controller_name = controller.class.name.gsub(/Controller$/, '').underscore.gsub("/", ".")
    # NOTE: raiseオプションを指定するとkeyが見つからなかったときに例外が発生する
    title ||= (I18n.t("page_titles.#{full_controller_name}.#{action_name}", :raise => true) rescue nil)
    title ||= I18n.t("page_titles.#{full_controller_name}_title") + t("page_titles.defaults.#{action_name}")
    h(title)
  end
  alias :page_title_mobile :page_title

  # ページ繰りUIの携帯版
  def will_paginate_mobile(records, options={})
    will_paginate(records, options.merge(:renderer => 'Mars::WillPaginate::LinkRendererForMobile',
                  :next_label => "[#{emoticon_6}次へ]", :previous_label => "[#{emoticon_4}前へ]"))
  end

  # フォーム画面で表示する注意書き
  def form_notation
    font_coution("※", :bold => true) + "は必須項目です。"
  end

  def form_notation_with_attachments
    form_notation + "<br />" +
      "[ファイル添付のご注意] 添付できるファイルサイズは全て合わせて" +
      font_coution(" 1MB ", :bold => true) + "までです。"
  end

  # フォーム画面で表示する注意書き（携帯用）
  def mobile_form_notation
    font_coution("※", :bold => true) + "は必須項目です。"
  end

  # 確認画面で表示する注意書き
  def confirm_notation
    return <<-HTML
      <font color="red">※送信内容を確認し、必ず<b>[ 送信する ]</b>
      ボタンをクリックして送信を完了してください。</font><br/>
      ※送信内容を保存する場合はこのページを印刷、または保存してください。<br/>
      HTML
  end

  # 確認画面で表示する注意書き（携帯用）
  def mobile_confirm_notation
    return <<-HTML
      <font color="red">※送信内容を確認し、必ず<b>[ 送信する ]</b>
      ボタンをクリックして送信を完了してください。</font><br/>
      ※送信内容を保存する場合はこのページを保存してください。<br/>
      HTML
  end

  def font_coution(str, options={:bold => false})
    res = %Q(<font color="red">#{str}</font>)
    res = %Q(<b>#{res}</b>) if options[:bold]
    return res
  end

  def font_note(str)
    %Q(<font color="green">#{str}</font>)
  end

  # ページ繰りUIを表示するか？
  def show_paginated_ui?(collection)
    WillPaginate::ViewHelpers.total_pages_for_collection(collection) > 1
  end

  # collection（オブジェクトの集合）を表示する際ののヘッダ、及びフッタの表示
  # ヘッダは、collectionの件数とページネーション
  # フッタは、何件ずつ表示するか、と何ページを表示するかのセレクトボックスと、ページネーション
  # will_paginateを使用していないときでも動作する
  #
  # ==== 引数
  # * options
  # * <tt>:collection_name</tt> - collectionの名前
  # * <tt>:per_pages</tt> - 何件ずつ表示するかの選択肢。配列。
  # * <tt>:checked_value</tt> - 何件ずつ表示するかの、デフォルト値
  # * <tt>:width</tt> - 表示領域の横幅
  # * <tt>:all_pages</tt> - 全件表示を選択可能にするかどうか
  # * <tt>:class</tt> - スタイルのクラス
  # * <tt>:form</tt> - formパラメータ
  def display_collection_box(collection, options = { })
    concat collection_header(collection, options)
    yield if block_given?
    collection_footer(collection, options)
  end

  # ファイル名の拡張子によって、アイコンを返す
  def icon_name_by_extname(file)
    extname = File.extname(file).gsub(/\A\./, "")

    case extname
    when "txt"
      "file.png"
    when "xls", "csv"
      "excel.png"
    when "doc"
      "word.png"
    when "pdf"
      "pdf.png"
    when "ppt"
      "powerpnt.png"
    when "zip", "lzh"
      "arc.png"
    when "jpg", "jpeg", "png", "gif"
      "pic.png"
    else
      "file.png"
    end
  end

  # Mars用RSS2フィードレイアウト
  #
  # ==== 引数
  # * options
  # * <tt>:title</tt>
  # * <tt>:link</tt>
  # * <tt>:description</tt>
  # * <tt>:carwings</tt> - true/falseのいずれか。
  #
  # ==== 備考
  #
  # carwingsについては以下のURLを参照(マップ系のRSSで使用する）
  # http://lab.nissan-carwings.com/CWC/
  def mars_rss2_feed_layout(xml, params={}, &block)
    rss_info = {"version" => "2.0",
      "xmlns:content" => "http://purl.org/rss/1.0/modules/content/"}
    if params[:carwings]
      rss_info["xmlns:carwings"] = "http://www.nissan.co.jp/dtd/carwings.dtd"
    end
    xml.rss(rss_info) do
      xml.channel do
        xml.title params[:title]
        xml.link params[:link]
        xml.description params[:description]
        xml.language "ja-jp"
        xml.pubDate Time.now.rfc822
        xml.lastBuildDate Time.now.rfc822
        xml.generator SnsConfig.title
        xml.copyright Mars::COPY_RIGHT
        block.call(xml)
      end
    end
    xml
  end

  # Mars用RDF(RSS1.0)フィードレイアウト
  #
  # ==== 引数
  # * options
  # * <tt>:title</tt>
  # * <tt>:link</tt>
  # * <tt>:description</tt>
  # * <tt>:resources</tt>
  def mars_rdf_feed_layout(xml, params={}, &block)
    xml.tag!("rdf:RDF",
             "xmlns" => "http://purl.org/rss/1.0/",
             "xmlns:rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
             "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
             "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
             "xmlns:sy" => "http://purl.org/rss/modules/syndication/",
             "xml:lang" => "ja") do
      xml.channel("rdf:about" => params[:link]) do
        xml.title params[:title]
        xml.link params[:link]
        xml.description params[:title]
        xml.tag!("dc:language", "ja")
        xml.tag!("dc:rights", Mars::COPY_RIGHT)
        xml.tag!("dc:date", Time.now.rfc822)
        xml.item do
          xml.tag!("rdf:Seq") do
            params[:resources].each do |resource|
              xml.tag!("rdf:li", "rdf:resource" => resource)
            end
          end
        end
      end
      block.call(xml)
    end
    xml
  end

  # Mars用Atomフィードレイアウト
  #
  # ==== 引数
  # * options
  # * <tt>:title</tt>
  # * <tt>:subtitle</tt>
  # * <tt>:root_url</tt>
  # * <tt>:author_name</tt>
  def mars_atom_feed_layout(xml, params={}, &block)
    atom_feed(:language => 'ja', :id => "", :root_url => params[:root_url]) do |feed|
      feed.title params[:title]
      feed.subtitle params[:subtitle]
      feed.author do
        feed.name SnsConfig.title
      end
      feed.updated Time.now
      feed.generator root_url, :uri => root_url, :vesion => 0
      feed.rights Mars::COPY_RIGHT
      block.call(feed)
    end
  end

  # 文字列をフィード用に正規化
  def normalize_text_for_feed(str)
    hbr(str).chomp
  end

  # Marsのイメージファイルの場所
  def mars_image_url(image_path)
    return URI.join("http://#{request.host_with_port}/images/", image_path).to_s
  end

  # RSS 2.0 の carwings:data 返却
  def mars_rss2_carwings_data(data)
    return <<HTML
<body>#{theme_image_tag("logo.gif")}
<font size="1">#{h(data)}</font></body>
HTML
  end

  # 文字列を携帯側の文字コードに変換
  #
  # ==== 備考
  #
  # getパラメータに日本語を指定して、次の画面でそのまま表示する様なケー
  # スの場合に使用。Jpmobileによって2回UTF-8変換されてしまうため。
  #
  # thanks : http://d.hatena.ne.jp/LukeSilvia/20071023/1193327000
  def reencode_to_mobile_code(str)
    filter = Jpmobile::Filter::Sjis.new

    if str && filter.apply_incoming?(controller)
      filter.to_external(str, controller)
    else
      str
    end
  end

  # ユーザの顔写真表示
  #
  # ==== 引数
  #
  # * options
  # * <tt>:image_type</tt> - 画像のタイプ（default :medium）
  # * <tt>:width</tt> - 横幅
  # * <tt>:height</tt> - 縦幅
  # * <tt>:no_photo_width</tt> - 横幅（顔写真がなかった場合）
  # * <tt>:no_photo_height</tt> - 縦幅（顔写真がなかった場合）
  def display_face_photo(photo, options={})
    if photo
      return theme_image_tag(face_photo_path(photo, :image_type => options[:image_type]),
                       :width => options[:width],
                       :height => options[:height])
    else
      if request.mobile?
        return ""
      else
        return theme_image_tag(face_photo_path(nil),
                         :width => (options[:no_photo_width] || options[:width]),
                         :height => (options[:no_photo_height] || options[:height]))
      end
    end
  end

  # 顔写真表示パス
  #
  # ==== 引数
  #
  # * options
  # * <tt>:image_type</tt> - 画像のタイプ（default :medium）
  def face_photo_path(photo, options={})
    options[:image_type] ||= :medium
    if photo
      return show_face_photo_users_path(:image_id => photo.id,
                                       :image_type => options[:image_type],
                                       :image_class => photo.class.to_s)
    else
      return "noface.gif"
    end
  end

  # ラベル名表示
  def display_label_name(label_prefix, name)
    unless name.blank?
      h(t("#{label_prefix}.#{name}"))
    end
  end

  # モデルに定義されている定数のセレクトボックスオプション生成
  #
  # ==== 引数
  #
  # * model_class_name
  # * const_name - VISIBILITIES等の定数
  # * options
  # * <tt>:name_space</tt> - I18nのラベル名ネームスペース
  # * <tt>:label_prefix</tt> - I18nのラベル名プレフィクス
  # * <tt>:choices</tt> - 表示したい定数内のキーを指定。
  #
  # ==== 戻り値
  #
  # ラベル名、キーの組配列
  def select_options_for_const(model_class_name, const_name, options={})
    options[:label_prefix] ||= const_name.downcase.singularize
    model_name = model_class_name.underscore
    const = "#{model_class_name}::#{const_name}".constantize
    if const.is_a?(ActiveSupport::OrderedHash)
      choices = const.keys
    else
      choices = const.sort_by do |_, v|
        v.methods.include?("to_i") ? v.to_i : 0
      end.map(&:first)
    end
    options[:choices] ||= choices

    options[:choices].map do |key|
      labels = []
      labels << options[:name_space] if options[:name_space]
      labels += [model_name, "#{options[:label_prefix]}_label", key]
      [t(labels.join(".")), const[key]]
    end
  end

  # フォームの項目名表示
  #
  # ==== 引数
  #
  # * klass - モデルクラス
  # * attribute_name - 項目名
  # * options
  # ** human_attribute_name - 日本語名
  # ** force_presence_mark - 必須か？(true/false)
  # ==== 戻り値
  # フォームの項目名表示
  def display_form_attr_name(klass, attribute_name, options={})
    res = options[:human_attribute_name].blank? ? klass.human_attribute_name(attribute_name) : options[:human_attribute_name]
    res = "[#{res}]"
    if options[:force_presence_mark] ||
        (klass.respond_to?(:presence_of_columns) &&
         klass.presence_of_columns.map(&:to_s).include?(attribute_name.to_s))
      res += font_coution("※")
    end
    return res.untaint
  end

  # ユーザとユーザのサイト内の関係性を表示
  def display_relationship_user_to_user(user, target_user)
    return nil if user.nil?
    user.relationship_to_user(target_user).map do |user|
      "[" + link_to_user(user, h(user.name)) + "]"
    end.join(" ⇒ ")
  end

  # テンプレートを呼び出す独自のエラーメッセージ表示メソッド
  #
  # ==== 補足
  #
  # 項目名が空文字の場合、そのメッセージは表示しない。
  # 表示させたくない項目名は空文字に設定すること。
  def template_error_messages_for(object, options={})
    options = options.symbolize_keys
    return nil unless object
    unless object.errors.empty?
      error_messages = object.errors.full_messages.map do |m|
        i = m.rindex(" ")
        if i.nil?
          ["", m]
        elsif i.zero?
          nil
        else
          [m[0...i], m[(i+1)..(m.length)]]
        end
      end.compact.map do |a, b|
        a.blank? ? b : "[#{a}]#{b}"
      end
      render :partial=>"share/error_messages_for",
      :locals => {:messages => error_messages, :object => object}
    end
  end

  # ユーザのプロフィールページへのリンクを表示するメソッド
  #
  # ==== 引数
  #
  # * user - 表示されるユーザ
  # * name - プロフィールページへのリンクの文言
  # * options
  # ** name_necessary - プロフィールページが見れなくても、nameだけは表示する
  #
  # === 補足
  #
  # ユーザのプロフィールページの公開範囲と、そのページを表示しようとするユーザによっては、リンクは埋め込まない
  def link_to_user(user, name, options = { }, &block)
    return name unless user
    options[:name_necessary] = true if options[:name_necessary].nil?
    return "" if (!user.profile_displayable?(current_user) && !options[:name_necessary])
    link_to_if user.profile_displayable?(current_user), name, user_path(user)
  end

  # 引数で与えられた文字列の中に含まれるURL（ただし、本システムに対するもののみ）に対して、session_idをクエリに追加する
  # ただし、携帯で無かったり，元々session_idがクエリとして渡ってきていない場合は無視する
  def add_session_query_on_inner_url(str)
    session_key = (request.session_options || ActionController::Base.session_options)[:key]
    session_id = request.session_options[:id] rescue session.session_id

    return str if !request.mobile? || params[session_key].blank?
    str.gsub(URI.regexp) do
      url = $&.dup
      if url =~ %r(https?://#{CONFIG["host"]})
        uri = URI.parse(url)
        if uri.query
          uri.query += "&#{session_key}=#{session_id}"
        else
          uri.query = "#{session_key}=#{session_id}"
        end
        uri.to_s
      else
        url
      end
    end
  end

  # url中の、session_query部分を除去する
  # ただし、携帯で無かったり，元々session_idがクエリとして渡ってきていない場合は無視する
  def strip_session_query(url)
    session_key = (request.session_options || ActionController::Base.session_options)[:key]
    session_id = request.session_options[:id] rescue session.session_id

    return url if !request.mobile? || params[session_key].blank?

    begin
      uri = URI.parse(url)
    rescue URI::InvalidURIError
      return url
    end

    query = uri.query
    if query
      uri.query = query.gsub(/\??#{session_key}=#{session_id}\&?/, "")
    end

    # uriの末尾が?や&amp;であれば削除する
    url = uri.to_s
    url.gsub(/[\?]\z/, "").gsub(/&amp;\z/, "")
  end


  # キャリアによって、subjectとbodyのエンコード方式が違う
  # docomoとauは、sjisでエンコードしないといけないので、そこだけ対応する
  def mail_to_for_mobile(email_address, name = nil, html_options = {})
    case request.mobile
    when Jpmobile::Mobile::Docomo, Jpmobile::Mobile::Au
      html_options[:subject] = NKF.nkf("-s", html_options[:subject]) unless html_options[:subject].blank?
      html_options[:body] = NKF.nkf("-s", html_options[:body]) unless html_options[:body].blank?
    end

    mail_to email_address, name, html_options
  end

  private

  def ordering_column?(options={})
    return true if params[:order] == options[:order]
    default_order = options[:default_order].to_s
    if params[:order].nil? && default_order.include?(options[:order])
      options[:order_modifier] = "DESC" if default_order.include?("DESC")
      options[:order_modifier] = "ASC" if default_order.include?("ASC")
      return true
    end
    return false
  end

  def collection_header(collection, options = { })
    width = options[:width] ? "width: #{options[:width].to_s};" : "width: 100%;"
    collection_name = options[:collection_name] || ""
    content_tag(:table, :cellspacing => 0, :border => 0, :align => "center", :style => "#{width} text-align: left;", :class => options[:class]) do
      content_tag(:tr) do
        total = collection.is_a?(WillPaginate::Collection) ? collection.total_entries : collection.count
        tr = ""
        tr << content_tag(:td, :align => "left", :width => "33%") do
          collection_name + "は" + total.to_s + "件です。"
        end
        if collection.is_a?(WillPaginate::Collection)
          tr << page_list(collection, collection_paginate_params(options))
          tr << next_and_prev_page(collection, collection_paginate_params(options))
        end
        tr
      end
    end
  end

  def collection_footer(collection, options = { })
    width = options[:width] ? "width: #{options[:width].to_s};" : "width: 100%;"
    per_pages = options[:per_pages] || []
    checked_value = options[:checked_value]

    table = content_tag(:table, :cellspacing => 0, :border => 0, :align => "center", :style => "#{width} text-align: left;", :class => options[:class]) do
      content_tag(:tr) do
        pages = collection.is_a?(WillPaginate::Collection) ? collection.total_pages : 1
        tr = ""
        tr << content_tag(:td, :align => "left", :width => "33%") do
          td = ""
          td << select_per_page(per_pages, :checked_value => checked_value, :all_pages => options[:all_pages])
          td << select_page(pages)
          td << submit_tag("表示")
        end
        if collection.is_a?(WillPaginate::Collection)
          tr << page_list(collection, collection_paginate_params(options))
          tr << next_and_prev_page(collection, collection_paginate_params(options))
        end
        tr
      end
    end
    form_url_options = {}
    form_options = {:method => :get}
    if params[:order]
      form_url_options[:order] = params[:order]
      form_url_options[:order_modifier] = params[:order_modifier]
      form_options[:method] = :post
    end
    if options[:form]
      form_url_options.merge!(options[:form][:url_for_options] || {})
      form_options.merge!(options[:form][:options] || {})
    end
    form_tag(form_url_options, form_options) { table }
  end

  def page_list(collection, url_for_options={})
    content_tag(:td, :align => "center", :width => "33%") do
      will_paginate(collection,
                    {:previous_label => "",
                     :next_label => "",
                     :outer_window => 0,
                     :params => url_for_options.merge(:per_page => params[:per_page])})
    end
  end

  def next_and_prev_page(collection, url_for_options={})
    content_tag(:td, :align => "right", :width => "33%") do
      will_paginate(collection,
                    {:previous_label => "[前のページ]",
                     :next_label => "[次のページ]",
                     :page_links => false,
                     :params => url_for_options.merge(:per_page => params[:per_page])})
    end
  end

  def collection_paginate_params(options={})
    return options[:form] ? (options[:form][:url_for_options] || {}) : {}
  end

  # エラー時のタイトル表示
  def error_title
    if defined?(form_params)  && defined?(form_params[:model_instance].errors) && !form_params[:model_instance].errors.empty?
      title = '-入力エラー'
    end
    return title ? title : ''
  end
end

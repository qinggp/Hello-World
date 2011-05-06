# -*- coding: utf-8 -*-
# ブログエントリ本文表示ヘルパ
#
# 新しいフォーマッタを追加したらこのモジュールにサニタイズ処理を定義し
# てください。
module Mars::Blog::EntryBodyViewHelper
  include ActionView::Helpers::SanitizeHelper

  # ブログエントリ本文表示
  #
  # ==== 引数
  #
  # * entry - ブログエントリレコード
  # * options[:allowed_tags] - エスケープしないタグ名
  # * options[:trancate_bytes] - 本文切りたいバイト数
  # * options[:display_type] - :raw(文字のみ), :br(文字と<br>のみ), :normal(標準：デフォルト), :confirm(確認画面での表示方法), :summary(簡単なタグを表示）
  #
  # ==== 戻り値
  #
  # サニタイズ済み本文
  def display_blog_entry_body(entry, opts={})
    dup_opts = {:allowed_tags => %w(b i u font hr img),
                :rendered_pics => [],
                :display_type => :normal}.merge(opts)
    dup_opts[:entry] = entry

    unless entry.body_format.nil? || entry.body_format.empty? || dup_opts[:display_type] == :summary
      return send("display_bolg_entry_body_for_#{entry.body_format}", entry, dup_opts)
    end
    html = blog_entry_body_escape(entry.body, dup_opts).untaint
    if dup_opts[:display_type] == :normal
      html << body_render_pic_to_footer(entry, dup_opts)
      html = auto_link(add_session_query_on_inner_url(html)) { |text| truncate(strip_session_query(text), 60) }
    end
    html
  end

  # 本文のエスケープ処理
  def blog_entry_body_escape(text, options = {})
    nodes = blog_entry_body_tokenize(text, options)
    if options[:trancate_bytes]
      nodes = blog_entry_body_truncate_html(nodes, options[:trancate_bytes], options)
    end
    html = nodes.join
    html.gsub!("\n", "<br/>") unless options[:display_type] == :raw
    html = wrap_div_style_overflow(html) unless %w(raw br summary).include?(options[:display_type].to_s)
    return html
  end

  private

  # WYSWYG用サニタイズ処理
  def display_bolg_entry_body_for_wyswyg(entry, opts={})
    opts[:allowed_tags] = %w(b i u font hr p br li ul hr div span h1 h2 h3 h4 h5 h6 strong em img a)
    html = blog_entry_body_escape(entry.body, opts).untaint
    html << body_render_pic_to_footer(entry, opts) if opts[:display_type] == :normal
    html = auto_link(add_session_query_on_inner_url(html)) { |text| truncate(strip_session_query(text), 60) }
    return html
  end

  # htmlをサニタイズせずに表示する際の処理
  def display_bolg_entry_body_for_no_escape(entry, opts={})
    opts[:no_escape] = true
    html = blog_entry_body_escape(entry.body, opts).untaint
    html << body_render_pic_to_footer(entry, opts) if opts[:display_type] == :normal
    html = auto_link(add_session_query_on_inner_url(html)) { |text| truncate(strip_session_query(text), 60) }
    return html
  end

  # HTMLをパース＆トークンを process_node に引き渡し
  def blog_entry_body_tokenize(text, options)
    tokenizer = HTML::Tokenizer.new(text)
    result = []
    options[:allowed_tags] ||= []
    options[:rendered_pics] ||= []
    while token = tokenizer.next
      node = HTML::Node.parse(nil, 0, 0, token, false)
      process_node node, result, options
    end
    result
  end

  # HTMLのエスケープ処理
  def process_node(node, result, options)
    if node.kind_of?(HTML::Tag)
      case
      when options[:display_type] == :raw || options[:display_type] == :br
        # HTMLタグは無視する
      when options[:allowed_tags].include?(node.name.downcase)
        result << node
      when node.name.downcase == "pic"
        result << body_render_pic(node, options)
      when node.name.downcase == "ext"
        result << body_render_ext(node, options)
      when options[:no_escape]
        # エスケープしない場合
        result << node
      else
        result << strip_tags(node.to_s)
      end
      return
    end
    result << node
  end

  # 画像を本文に表示
  def body_render_pic(node, options={})
    case options[:display_type]
    when :normal
      attachment =  BlogAttachment.find(:first, :conditions => {
                                          :blog_entry_id => options[:entry].id,
                                          :position => node["no"].to_i})
      if attachment
        options[:rendered_pics] << node["no"]
        return display_attachment_file(attachment,
                 :attachment_path => show_unpublic_image_blog_entry_path(options[:entry],
                                       :blog_attachment_id => attachment.id,
                                       :image_type => "medium"),
                 :original_attachment_path => show_unpublic_image_blog_entry_path(options[:entry],
                                       :blog_attachment_id => attachment.id)
        )
      end
      return ""
    when :confirm
      options[:rendered_pics] << node["no"]
      return "[画像：#{h(node.attributes["no"])}]"
    else
      return ""
    end
  end

  # 拡張タグを本文に表示
  def body_render_ext(node, options={})
    case options[:display_type]
    when :normal, :confirm
      if node.attributes["type"] == "youtube"
        return create_embedded_youtube_tag(node)
      elsif node.attributes["type"] == "matsue_movie"
        return create_embedded_matsue_movie_tag(node)
      end
    end
    return ""
  end

  # 本文の下に画像表示
  def body_render_pic_to_footer(entry, options)
    html = "<div>"
    entry.blog_attachments.each do |attachment|
      unless options[:rendered_pics].include?(attachment.position.to_s)
        html << display_attachment_file(attachment,
                 :attachment_path => show_unpublic_image_blog_entry_path(entry,
                                       :blog_attachment_id => attachment.id,
                                       :image_type => "medium"),
                 :original_attachment_path => show_unpublic_image_blog_entry_path(entry,
                                       :blog_attachment_id => attachment.id)
        )
      end
    end
    html << "</div>"
    return html
  end

  # 文字列を切り取る必要があるか
  def body_require_trancate?(str, options)
    if options[:trancate_bytes] && str.bytesize > options[:trancate_bytes]
      return true
    end
    return false
  end

  # divでラップ
  def wrap_div_style_overflow(html)
    content_tag(:div, :style => "overflow: auto; margin-bottom:10px;") do
      html
    end
  end

  # youtube埋め込みタグ作成
  def create_embedded_youtube_tag(node)
    url = "http://www.youtube.com/v/"
    if node.attributes["data"].include?(url)
      url = node.attributes["data"]
    else
      query = URI.parse(node.attributes["data"]).query
      return "" if query.blank?

      q_params = CGI.parse(query)
      return "" if q_params["v"].blank?
      url += q_params["v"].first
    end

    return link_to("[YouTube動画]", url) if request.mobile?

    height = node.attributes["height"] || 268
    width = node.attributes["width"] || 325
    content_tag("object", :height => height, :width => width) do
      html = ""
      html << content_tag("params", nil, :value => url, :name => "movie")
      html << content_tag("params", nil, :value => "transparent", :name => "movie")
      html << content_tag("embed", nil, :height => height,
                          :width => width, :wmode => "transparent",
                          :type => "application/x-shockwave-flash", :src => url)
      html
    end
  end

  # 松江SNSのムービー埋め込み
  def create_embedded_matsue_movie_tag(node)
    return "" if node.attributes["data"].blank?
    id = node.attributes["data"].split("/").compact.last
    return "" if id.blank?
    return "" unless ::Movie.exists?(id.to_i)
    return link_to("[#{h SnsConfig.title}動画]", movie_path(:id => id)) if request.mobile?

    height = node.attributes["height"] || 320
    width = node.attributes["width"] || 400
    url = flash_file_movie_path(id, :file => "movie.flv")

    html = content_tag("div", "ここに Flash が表示されます", :id => "flashcontent_#{id}")
    html << content_tag("script", :type => "text/javascript") do
      js = ""
      js << %Q(var so = new SWFObject("/javascripts/movie/swf/mediaplayer.swf", "#{h SnsConfig.title}", #{width.to_json}, #{height.to_json}, "7");)
      js << %Q(so.addParam("allowfullscreen", "true");)
      js << %Q(so.addVariable("width", #{width.to_json});)
      js << %Q(so.addVariable("height", #{height.to_json});)
      unless id.blank?
        js << %Q(so.addVariable("file", #{url.to_json});)
      end
      js << %Q(so.write("flashcontent_#{id}");)
      js
    end
    html
  end

  # ブログの本文切り取り(HTMLタグを考慮)
  def blog_entry_body_truncate_html(html_nodes, len, options)
    res = []
    not_closing_tags = []
    new_len = len
    html_nodes.each do |node|
      case node
      when HTML::Text
        l = node.content.mb_chars.length
        res << truncate(node.content, :length => new_len, :omission => "") if new_len <= l
        new_len -= l
        break if new_len <= 0
      when HTML::Tag
        if node.closing == :close && not_closing_tags.last &&
            not_closing_tags.last.name == node.name
          not_closing_tags.pop
        elsif node.closing != :self
          # NOTE: 閉じタグを省略して登録されている恐れのあるタグを除外
          not_closing_tags << node unless %w(hr PIC EXT).include?(node.name)
        end
      end
      res << node
    end

    res = res +
      not_closing_tags.reverse.map{|tag| HTML::Tag.new(nil, nil, nil, tag.name, nil, :close) }
    if new_len <= 0 || options[:entry].imported_by_rss
      res << blog_entry_body_truncate_html_omission(options[:entry])
    end
    return res
  end

  # ブログ本文の省略文言
  def blog_entry_body_truncate_html_omission(entry)
    omission = "..."
    if entry.imported_by_rss
      omission << "[" + link_to("続きを読む", h(entry.rss_url)) + "]"
      omission << "(" + theme_image_tag("outlink.gif") +"リンク先は、#{h SnsConfig.title}の外のコンテンツになります)"
    else
      omission << "[" + link_to("続きを読む", blog_entry_path(entry)) + "]"
    end
  end
end

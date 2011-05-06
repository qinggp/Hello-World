# Mars用ページ繰りUIレンダラー
module Mars::WillPaginate
  class LinkRenderer < WillPaginate::LinkRenderer
    @@prev_flg, @@next_flg = false, false
    def to_html
      links = @options[:page_links] ? windowed_links : []

      html = links.join(@options[:separator])
      html = "[#{html}]" if @options[:page_links]
      # previous/next buttons
      if @options[:previous_label] != '' || @options[:next_label] != '' 
        html = page_link_or_span(@collection.previous_page, 'disabled prev_page', @options[:previous_label]) +
               html +
               page_link_or_span(@collection.next_page,     'disabled next_page', @options[:next_label])
      else
        html = html
      end
      @options[:container] ? @template.content_tag(:div, html, html_attributes) : html
    end

    def page_link_or_span(page, span_class, text = nil)
      text ||= page.to_s

      if page and page != current_page
        classnames = span_class && span_class.index(' ') && span_class.split(' ', 2).last
        # accesskey を追加しました。
        if text =~ /^[+-]?\d+$/ 
          page_link page, text, :rel => rel_value(page), :class => classnames
        else
          if span_class == 'disabled prev_page' && !@@prev_flg
            @@prev_flg = true
            page_link page, text, :rel => rel_value(page), :class => classnames, :accesskey => accesskey(page)
          elsif span_class == 'disabled next_page' && !@@next_flg
            @@next_flg = true
            page_link page, text, :rel => rel_value(page), :class => classnames, :accesskey => accesskey(page)
          else
            page_link page, text, :rel => rel_value(page), :class => classnames
          end
        end
      else
        page_span page, text, :class => span_class
      end
    end

    private
    def accesskey(page)
      case page
      when @collection.previous_page; '7'
      when @collection.next_page; '9'
      else '';
      end
    end

  end

  class LinkRendererForMobile < WillPaginate::LinkRenderer
    def to_html
      links = @options[:page_links] ? windowed_links : []
      # previous/next buttons
      links.unshift page_link_or_span(@collection.next_page,     'disabled next_page', @options[:next_label])
      links.unshift page_link_or_span(@collection.previous_page, 'disabled prev_page', @options[:previous_label])

      html = links.join(@options[:separator])
      @options[:container] ? @template.content_tag(:div, html, html_attributes) : html
    end

    def windowed_links
      ["（#{current_page}/#{total_pages}）"]
    end

    protected

    def page_link_or_span(page, span_class, text = nil)
      text ||= page.to_s

      if page and page != current_page
        classnames = span_class && span_class.index(' ') && span_class.split(' ', 2).last
        # accesskey を追加しました。
        page_link page, text, :rel => rel_value(page), :class => classnames, :accesskey => accesskey(page)
      else
        page_span page, text, :class => span_class
      end
    end

    private
    def accesskey(page)
      case page
      when @collection.previous_page; '4'
      when @collection.next_page; '6'
      else '';
      end
    end
  end
end

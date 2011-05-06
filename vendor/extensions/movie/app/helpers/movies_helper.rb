module MoviesHelper
  # 確認画面のForm情報
  def confirm_form_params
    if @movie.new_record?
      {:url => movies_path, :method => :post,
        :model_instance => @movie
      }
    else
      {:url => movie_path(@movie), :method => :put,
        :model_instance => @movie
      }
    end
  end

  # 登録・編集画面のForm情報
  def form_params
    if @movie.new_record?
      {:url => confirm_before_create_movies_path,
        :model_instance => @movie,
        :multipart => true
      }
    else
      {:url => confirm_before_update_movies_path(:id => @movie.id),
        :model_instance => @movie,
        :multipart => true
      }
    end
  end

  # フォーム表示時の注意書き
  def form_notation
    res = super
    if @movie.new_record?
      res << "<br/>"
      res << "一人あたりの登録できる容量は最大"
      res << h(number_to_human_size(Mars::Movie::ResourceLoader['application']['movie_limited_size'].to_i, :precision => 0))
      res << " です。<br/>"
    end
    res
  end

  def public_to_s(movie)
    t("movie.movie_preference.visibility_label.#{k}")
  end

  # 公開範囲オプション返却
  def visibility_options
    values = []
    MoviePreference::VISIBILITIES.sort_by{|k, v| -v}.map do |k, v|
      values << [t("movie.movie_preference.visibility_label.#{k}"), v]
    end
    return values
  end

  def link_to_username(user)
    link_to_user user, h(user.name)
  end

  def link_to_remote_for_prev_page(collection, options = {})
    label  = options[:label] || h('<< previous page')
    update = options[:update]
    action = options[:action]

    raise ArgumentError.new('update and action cannot be blank!!') if update.blank? || action.blank?

    if collection.previous_page
      return link_to_remote(label, :update => update,
                            :url => { :action => action, :page => collection.previous_page, :per_page => collection.per_page })
    else
      return label
    end
  end

  def link_to_remote_for_next_page(collection, options = {})
    label  = options[:label] || h('next page >>')
    update = options[:update]
    action = options[:action]

    raise ArgumentError.new('update and action cannot be blank!!') if update.blank? || action.blank?

    if collection.next_page
      return link_to_remote(label, :update => update,
                            :url => { :action => action, :page => collection.next_page, :per_page => collection.per_page })
    else
      return label
    end
  end

  def link_to_remote_for_page_numbers(collection, options = {})
    return '' if collection.total_pages == 0

    update    = options[:update]
    action    = options[:action]
    separator = options[:separator] || ' '
    raise ArgumentError.new('update and action cannot be blank!!') if update.blank? || action.blank?

    from = collection.current_page - 5
    to = collection.current_page + 5
    if from < 1
      to += (1 - from)
      from = 1
    else
      from += 1
    end

    if to > collection.total_pages
      if (from - (to - collection.total_pages)) > 1
        from -= to - collection.total_pages
      else
        from = 1
      end
      to = collection.total_pages
    else
      to -= 1
    end

    page_numbers = (from..to).to_a
    if from != 1
      page_numbers.unshift(nil)
      page_numbers.unshift(1)
    end
    if to != collection.total_pages
      page_numbers.push(nil)
      page_numbers.push(collection.total_pages)
    end


    pages = []
    page_numbers.each do |page_number|
      if page_number.nil?
        pages << "..."
      elsif page_number == collection.current_page
        pages << "#{page_number}"
      else
        pages << link_to_remote("#{page_number}", :update => update,
                                :url => { :action => action, :page => page_number, :per_page => collection.per_page })
      end
    end

    return pages.join(separator)
  end

  def link_to_prev_page_for_search(collection, options = {})
    label  = options[:label] || h('<< previous page')
    action = options[:action]
    query  = options[:query]

    raise ArgumentError.new('action cannot be blank!!') if action.blank?

    link_to_if(collection.previous_page, label,
               { :action => action, :page => collection.previous_page, :per_page => collection.per_page, :query => query })
  end

  def link_to_next_page_for_search(collection, options = {})
    label  = options[:label] || h('next page >>')
    action = options[:action]
    query  = options[:query]

    raise ArgumentError.new('action cannot be blank!!') if action.blank?

    link_to_if(collection.next_page, label,
               { :action => action, :page => collection.next_page, :per_page => collection.per_page, :query => query})
  end

  def link_to_page_numbers_for_search(collection, options = {})
    return '' if collection.total_pages == 0

    action    = options[:action]
    query     = options[:query]
    separator = options[:separator] || ' '

    raise ArgumentError.new('action cannot be blank!!') if action.blank?

    from = collection.current_page - 5
    to = collection.current_page + 5
    if from < 1
      to += (1 - from)
      from = 1
    else
      from += 1
    end

    if to > collection.total_pages
      if (from - (to - collection.total_pages)) > 1
        from -= to - collection.total_pages
      else
        from = 1
      end
      to = collection.total_pages
    else
      to -= 1
    end

    page_numbers = (from..to).to_a
    if from != 1
      page_numbers.unshift(nil)
      page_numbers.unshift(1)
    end
    if to != collection.total_pages
      page_numbers.push(nil)
      page_numbers.push(collection.total_pages)
    end


    pages = []
    page_numbers.each do |page_number|
      if page_number.nil?
        pages << "..."
      elsif page_number == collection.current_page
        pages << "#{page_number}"
      else
        pages << link_to("#{page_number}",
                         { :action => action, :page => page_number, :per_page => collection.per_page, :query => query })
      end
    end

    return pages.join(separator)
  end

  def search_highlight(text, phrases, highlighter = '<strong class="highlight">\1</strong>')
    if text.blank? || phrases.blank?
      text
    else
      match = Array(phrases).map {|p| Regexp.escape(p) }.join('|')
      text.gsub(/(#{match})/i, highlighter)
    end
  end

  def escape_string_for_js(string)
    hbr(string)
  end

  # モバイル別のムービーファイルダウンロードパス返却
  def mobile_movie_file_download_path(movie)
    if request.mobile == Jpmobile::Mobile::Au
      mobile_3g2_file_movie_path(movie)
    else
      mobile_3gp_file_movie_path(movie)
    end
  end

  # ムービーファイルサイズ取得
  def mobile_movie_file_size(movie)
    if request.mobile == Jpmobile::Mobile::Au
      movie.file_size("3g2")
    else
      movie.file_size("3gp")
    end
  end
end

module UsersHelper
  def display_friend(friend)
    html = ""
    html << (link_to_user friend, display_face_photo(friend.face_photo, :width => "76"))
    html << content_tag(:div) do
      div = ""
      div << theme_image_tag("invite.png") if displayed_user.invitation?(friend)
      div << (link_to_user friend, (h(friend.name_with_suffix) + "(#{friend.friends.size})"))
    end
  end

  # 確認画面のForm情報
  def form_params
    if @user.new_record?
      {:url => confirm_before_create_users_path,
        :model_instance => @user,
        :multipart => true}
    else
      {:url => confirm_before_update_users_path(:id => @user.id),
        :model_instance => @user,
        :multipart => true}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @user.new_record?
      {:url => users_path(current_user), :method => :post,
        :model_instance => @user}
    else
      {:url => user_path(@user), :method => :put,
        :model_instance => @user}
    end
  end

  # OpenID登録・編集画面のForm情報
  def form_openid_params
    return {
      :url => confirm_before_update_openid_users_path,
      :model_instance => @user
    }
  end

  # OpenID確認画面情報
  def confirm_form_openid_params
    return {
      :url => open_id_authentication_for_update_users_path,
      :model_instance => @user
    }
  end

  # ID、パスワード編集画面のForm情報
  def form_id_password_params
    return {
      :url => confirm_before_update_id_password_users_path,
      :model_instance => @user
    }
  end

  # ID、パスワード確認画面情報
  def confirm_form_id_password_params
    return {
      :url => update_id_password_users_path,
      :model_instance => @user
    }
  end

  # 本名リクエスト編集画面のForm情報
  def form_request_new_name_params
    return {
      :url => confirm_before_request_new_name_users_path,
      :model_instance => @user
    }
  end

  # 本名リクエスト確認画面のForm情報
  def confirm_form_request_new_name_params
    return {
      :url => request_new_name_users_path,
      :model_instance => @user
    }
  end

  # 退会情報編集画面のForm情報
  def form_leave_params
    return {
      :url => confirm_before_leave_users_path,
      :model_instance => @user
    }
  end

  # 退会情報確認画面情報
  def confirm_form_leave_params
    return {
      :url => leave_users_path,
      :model_instance => @user
    }
  end

  # 携帯メールアドレス情報編集画面のForm情報
  def form_mobile_email_params
    return {
      :url => confirm_before_update_mobile_email_users_path,
      :model_instance => @user
    }
  end

  # 携帯メールアドレス情報確認画面情報
  def confirm_form_mobile_email_params
    return {
      :url => update_mobile_email_users_path,
      :model_instance => @user
    }
  end

  # トモダチ申請承認画面のForm情報
  def form_approve_friend_params
    return {
      :url => confirm_before_approve_friend_user_path(displayed_user),
      :model_instance => @friendship
    }
  end

  # トモダチ申請承認確認画面情報
  def confirm_approve_friend_params
    return {
      :url => approve_friend_user_path(displayed_user),
      :model_instance => @friendship
    }
  end

  # トモダチ申請画面のForm情報
  def form_friend_application_params
    return {
      :url => confirm_before_create_friend_application_user_path(displayed_user),
      :model_instance => @friendship
    }
  end

  # トモダチ申請確認画面情報
  def confirm_friend_application_params
    return {
      :url => create_friend_application_user_path(displayed_user),
      :model_instance => @friendship
    }
  end

  # 趣味選択チェックボックス表示
  #
  # ==== 戻り値
  #
  # HTML
  def hobby_checkboxes
    hobbies = Hobby.ascend_by_position

    content_tag(:table, :class => "no_border") do
      table = ""
      hobbies.in_groups_of(4).each do |gh|
        table << content_tag(:tr) do
          tr = ""
          gh.each_with_index do |h, i|
            tr << content_tag(:td, :width => "25%") do
              td = ""
              if h.nil?
                td = "&nbsp;"
              else
                td << hobby_checkbox(h, displayed_user, h.id)
              end
            end
          end
          tr
        end
      end
      table
    end
  end

  # 趣味選択チェックボックス表示（携帯用）
  #
  # ==== 戻り値
  #
  # HTML
  def hobby_checkboxes_mobile
    hobbies = Hobby.ascend_by_position
    i = 0
    hobbies.map{|h| hobby_checkbox(h, displayed_user, i+=1) }.join("<br/>")
  end

  # 編集画面の添付画像表示
  def form_attachment_image(form, user)
    html = ""
    html << display_face_photo_for_form(user, :image_type => :medium, :form => true)
    html << form.hidden_field(:id)
    html << "<br/>"
    return html
  end

  # 確認画面の添付画像表示
  def confirm_attachment_image(form, user)
    attachment = user.face_photo
    return if attachment.nil?
    html = ""
    if attachment.new_record?
      if attachment.image
        html << display_temp_attachment_file(attachment, :image_type => "medium", :form => true)
      else
        html << form.hidden_field(:_delete, :value => "1")
      end
    else
      html << "（削除）<br/>" if attachment._delete
      html << "（修正）<br/>" if attachment.image_changed?
      if attachment.image_changed?
        html << display_temp_attachment_file(attachment, :image_type => "medium", :form => true)
      else
        html << display_face_photo_for_form(user, :image_type => :medium, :form => true)
      end
      html << form.hidden_field(:_delete)
    end
  end

  # プロフィール項目種別名
  #
  # ==== 引数
  #
  # * name - 種別名
  # * label_name - ラベル名
  def display_profile_type_name(name, label_name)
    unless name.blank?
      return t("user.#{label_name}_label.#{name}")
    end
    return ""
  end

  # プロフィール項目公開範囲表示
  #
  # ==== 引数
  #
  # * name - 公開範囲名
  def display_profile_visibility_name(name)
    if displayed_user.same_user?(current_user)
      return font_coution(h("[" + t("user.visibility_label.#{name}") + "]"))
    end
    return ""
  end

  # パスワードの伏せ字
  def not_print_password(password)
    "*" * password.size unless password.blank?
  end

  # mixi風レイアウトスタイルシート生成
  def mixi_myhome_layout_style
    css = <<EOF
#my_contents {
  float:right;
  width:490px;
}

#my_navigation {
  float:left;
  width:240px;
}
EOF
    style = %Q(<style type="text/css">)
    style << css
    style << %Q(</style>)
    return style
  end

  # プロフィール画面の最上部にレンダリングする部分テンプレートパス
  def render_profile_header
    return "" if !logged_in? ||
    unless @profile_header_partial.blank?
      return render(:partial => "profile_header",
                    :locals => {:profile_header_partial => @profile_header_partial})
    end
    case
    when displayed_user.same_user?(current_user) #自分のプロフィール
      partial = "profile_header_my_profile"
    when current_user.friend_user?(displayed_user) #トモダチ
      partial = "profile_header_already_friend"
    when displayed_user.friendship_by_user_id(current_user.id) #トモダチ承認
      partial = "profile_header_approve_friend"
    else #トモダチ申請リンク
      partial = "profile_header_applicate_friend"
    end
    return render(:partial => "profile_header",
                  :locals => {:profile_header_partial => partial})
  end

  # ボックスの表示・非表示を切り替えるボタン
  def display_open_colse_box_button(id)
    if cookies[id].blank?
      up_style = "display:none;"
    else
      close_style = "display:none;"
    end
    return theme_image_tag("z_up.gif", :id => "#{id}_open", :style => up_style, :onclick => "Users.box_open(#{id.to_s.to_json})") +
      theme_image_tag("z_down.gif", :id => "#{id}_close", :style => close_style, :onclick => "Users.box_close(#{id.to_s.to_json})")
  end

  # 表示・非表示と切り替わるボックス（div）
  def display_open_colse_box(options={})
    opts = options.dup
    opts[:style] = opts[:style].to_s + "display:none;" unless cookies[opts[:id]].blank?
    html = content_tag(:div, opts){ yield if block_given? }
    concat html
  end

  # 新着情報一覧条件の期間セレクトボックスの値
  def news_show_option_span_select_value(id, options={})
    opts = {:default_span => "14"}.merge(options)
    span_id = "#{id}_span"
    return cookies[span_id].blank? ? opts[:default_span] : cookies[span_id]
  end

  # 新着情報一覧条件の件数セレクトボックスの値
  def news_show_option_count_select_value(id, options={})
    opts = {:default_count => "10"}.merge(options)
    count_id = "#{id}_count"
    return cookies[count_id].blank? ? opts[:default_count] : cookies[count_id]
  end

  # 新着情報、外部RSS含むか？
  def news_show_option_included_rss?(id)
    rss_id = "#{id}_rss"
    return true if !cookies[rss_id].blank? && cookies[rss_id] == "true"
    return false
  end

  # 新着情報一覧の条件セレクトボックス表示
  def display_news_show_option_selects(id, options={})
    html = ""
    span_id = "#{id}_span"
    html << select_tag(span_id,
                       options_for_select([["2週間分", "14"], ["1週間分", "7"], ["3日間分", "3"]],
                         news_show_option_count_select_value(id, options)),
                       :onchange => "Users.set_cookie_for_news_show_options(#{span_id.to_json})")
    count_id = "#{id}_count"
    html << select_tag(count_id,
                       options_for_select([["5件", "5"],["10件", "10"], ["20件", "20"], ["30件", "30"]],
                         news_show_option_count_select_value(id, options)),
                       :onchange => "Users.set_cookie_for_news_show_options(#{count_id.to_json})")
    return html
  end

  # 新着情報一覧のRSS条件セレクトボックス表示
  def display_news_show_rss_option_selects(id)
    html = ""
    rss_id = "#{id}_rss"
    html << select_tag(rss_id,
                       options_for_select([["内部のみ", ""], ["RSS含む", "true"]],
                         news_show_option_included_rss?(id) ? "true" : ""),
                       :onchange => "Users.set_cookie_for_news_show_options(#{rss_id.to_json})")
    html << content_tag(:span, :style => "font-size: 9px; height: 16px;"){ "※RSSを含むと表示が遅くなります。" }
    return html
  end

  # ページネーション用のパラメータ選択
  def select_search_member_params_for_paginate_mobile(*attr_names)
    res = {}
    res[:user] = {}
    attr_names.each do |attr|
      value = params[:user][attr]
      res[:user][attr] = reencode_to_mobile_code(value) unless value.blank?
    end
    return res
  end

  private

  # 顔写真表示
  #
  # ==== 引数
  #
  # * options
  # * <tt>:image_type</tt> - 画像のタイプ
  # * <tt>:form</tt> - formで使用するかどうか
  def display_face_photo_for_form(user, options={})
    if user.face_photo_uploaded?
      path = show_face_photo_users_path(:image_id => user.face_photo.id,
                                        :image_type => options[:image_type],
                                        :image_class => user.face_photo.class.to_s)
      default_opts = {:original_attachment_path => path,
                      :attachment_path => path}
      return display_attachment_file(user.face_photo, options.merge(default_opts))
    end
    return ""
  end

  # 趣味チェックボックス生成
  def hobby_checkbox(hobby, user, index)
    if params[:user] && params[:user][:users_hobbies_attributes]
      # 作成・編集画面に何らかの理由で戻ってきたとき
      # チェックされていた趣味だけ、チェックをつける
      checked_hobby_ids = params[:user][:users_hobbies_attributes].map{|v| v[:hobby_id].to_i }.compact
      check = check_box_tag("user[users_hobbies_attributes][][hobby_id]", hobby.id,
                            checked_hobby_ids.include?(hobby.id))
    else
      # はじめて作成・編集画面に訪れたとき
      check = check = check_box_tag("user[users_hobbies_attributes][][hobby_id]", hobby.id, user.hobbies.include?(hobby))
    end

    return check + label_tag("hobby_#{hobby.id}", h(hobby.name))
  end

  # 確認画面において、選択されている趣味を出力する
  def display_users_hobbies(users_hobbies_attributes)
    hobby_ids = users_hobbies_attributes.try(:map){|v| v["hobby_id"] }
    hobbies = Hobby.find_all_by_id(hobby_ids, :order => "id")
    hobbies.try(:map, &:name).join("<br />")
  end
end

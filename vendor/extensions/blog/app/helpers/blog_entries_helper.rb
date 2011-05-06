# -*- coding: utf-8 -*-
# ブログエントリヘルパ
module BlogEntriesHelper
  include BlogCommentsHelper
  include Mars::Blog::EntryBodyViewHelper
  include BlogCategoriesViewHelper

  mattr_reader :tiny_mce_options
  @@tiny_mce_options = {
    :language => "ja",
    :theme => "advanced",
    :mode => "exact",
    :elements => "blog_entry_body_by_wyswyg",
    :width => 500,
    :height => 400,
    :content_css => "/javascripts/tiny_mce/tiny_mce.css",
    :extended_valid_elements => "hr[class|width|size|noshade],font[face|size|color|style],span[class|align|style],img[width|height|border|class|title|alt|mce_src|src],a[href|title|target]",
    :theme_advanced_toolbar_location => "top",
    :theme_advanced_toolbar_align => "left",
    :theme_advanced_blockformats => "p,h1,h2,h3,h4,h5,h6",
    :theme_advanced_resizing => true,
    :theme_advanced_resize_horizontal => false,
    :theme_advanced_more_colors => false,
    :theme_advanced_statusbar_location => "bottom",
    :plugins => "pic, youtube, paste, searchreplace, advhr, contextmenu, inlinepopups, preview",
    :theme_advanced_buttons1 => "bold, italic, underline, advhr, separator, justifyleft, justifycenter, justifyright, separator,  bullist, numlist, separator, formatselect, fontsizeselect, forecolor",
    :theme_advanced_buttons3 => "",
    :plugin_preview_pageurl => "../../../blog/tiny_mce_preview.html",
#    :document_base_url => "/",
    :convert_urls => false,
    :relative_urls => false,
  }
  @@tiny_mce_options[:theme_advanced_buttons2] = "pic, youtube"
  if BlogExtension.instance.extension_enabled?(:movie)
    @@tiny_mce_options[:plugins] += ", matsue_movie"
    @@tiny_mce_options[:theme_advanced_buttons2] += ", matsue_movie"
  end
  @@tiny_mce_options[:theme_advanced_buttons2] += ", separator, removeformat, undo, redo, separator, search, replace, separator, preview"

  # 投稿時間、もしくは現在時刻を返す
  #
  # ==== 引数
  #
  # * entry - ブログエントリ
  #
  # ==== 戻り値
  #
  # Timestamp
  def post_time_or_now(entry)
    if entry.new_record?
      Time.now
    else
      entry.created_at
    end
  end

  # 確認画面のForm情報
  def confirm_form_params
    if @blog_entry.new_record?
      {:url => blog_entries_path, :method => :post,
        :model_instance => @blog_entry
      }
    else
      {:url => blog_entry_path(@blog_entry), :method => :put,
        :model_instance => @blog_entry
      }
    end
  end

  # 登録・編集画面のForm情報
  def form_params
    if @blog_entry.new_record?
      {:url => confirm_before_create_blog_entries_path,
        :model_instance => @blog_entry,
        :multipart => true
      }
    else
      {:url => confirm_before_update_blog_entries_path(:id => @blog_entry.id),
        :model_instance => @blog_entry,
        :multipart => true
      }
    end
  end

  # 登録・編集画面で表示する注意文
  def form_notation
    font_coution("※", :bold => true) + "は必須項目です。" + "<br />" +
      "[ファイル添付のご注意] 添付できるファイルサイズは全て合わせて" +
      font_coution(" 3MB ", :bold => true) + "までです。"
  end

  # TinyMCEによるWYSWYG表示
  def use_tiny_mce
    returning "" do |js|
      if logged_in? &&
          current_user.preference.blog_preference.wyswyg_editor?
        js << javascript_include_tag('tiny_mce/tiny_mce')
        options = tiny_mce_options.merge(@tiny_mce_options || {})
        js << javascript_tag("tinyMCE.init(#{options.to_json});")
      end
    end
  end

  # ブログエントリ本文のsetter名選択
  def choice_body_setter_name
    if logged_in? &&
        current_user.preference.blog_preference.wyswyg_editor?
      return :body_by_wyswyg
    end
    return :body
  end

  # 制限用ラジオボタン生成
  #
  # ==== 引数
  #
  # * column_name - カラム名
  # * f - form
  #
  # ==== 戻り値
  #
  # ラジオボタンHTML
  # ブログ新規作成のとき、 ブログ全体の公開設定が「外部公開」のときは、コメント制限の初期値を「メンバーのみ」にする
  def restraint_radio_button_for(column_name, f)
    html = ""
    selectable_values = current_user.preference.blog_preference.
      selectable_visibilities(%w(publiced friend_only member_only unpubliced))

    selectable_values.each_with_index do |(key, value), i|
      options = {}
      if column_name == :comment_restraint && current_user.preference.blog_preference.visibility_publiced? && f.object.new_record? && value == BlogPreference::VISIBILITIES[:member_only] && params[:blog_entry].blank?
        # ブログが新規作成で、ブログ全体の公開設定が「外部公開」のときは、コメント制限の初期値を「メンバーのみ」にする
        options[:checked] = true
      else
        options[:checked] = true if f.object.new_record? && i == 0
      end
      html << f.radio_button(column_name, value, options)
      html << f.label("#{column_name}_#{value}", t("blog.blog_entry.#{column_name}_label.#{key}"))
    end

    return html
  end


  # 制限用セレクトボックス生成
  #
  # ==== 引数
  #
  # * column_name - カラム名
  # * f - form
  #
  # ==== 戻り値
  #
  # セレクトボックス用のオプションリスト
  # ブログ新規作成のとき、 ブログ全体の公開設定が「外部公開」のときは、コメント制限の初期値を「メンバーのみ」にする
  def restraint_select_for(column_name, f)
    options = {}
    selectable_values = current_user.preference.blog_preference.
      selectable_visibilities(%w(publiced friend_only member_only unpubliced))

    selectable_values.each_with_index do |(key, value), i|
      if column_name.to_sym == :comment_restraint && current_user.preference.blog_preference.visibility_publiced? && f.object.new_record? && value == BlogPreference::VISIBILITIES[:member_only] && params[:blog_entry].blank?
        # ブログが新規作成で、ブログ全体の公開設定が「外部公開」のときは、コメント制限の初期値を「メンバーのみ」にする
        options[:selected] = value
      end
    end

    selectable_values.map! do |key, value|
      [t("blog.blog_entry.#{column_name}_label.#{key}"), value]
    end
    return f.select column_name, selectable_values, options
  end

  # 登録・編集画面の添付画像表示
  def form_attachment_image(attachment)
    html = ""
    unless attachment.new_record?
      html << display_attachment_file(attachment, :image_type => :medium, :form => true)
      html << "<br/>"
    end
    return html
  end

  # 確認画面の添付画像表示
  def confirm_attachment_image(form, attachment)
    html = ""
    if attachment.new_record?
      html << "<br/>"
      if attachment.image
        html << display_temp_attachment_file(attachment, :image_type => "medium")
      else
        html << form.hidden_field(:_delete, :value => "1")
      end
    else
      html << "（削除）" if attachment._delete
      html << "（修正）" if attachment.image_changed?
      html << "<br/>"
      if attachment.image_changed?
        html << display_temp_attachment_file(attachment, :image_type => "medium")
      else
        html << display_attachment_file(attachment, :image_type => :medium)
      end
      html << form.hidden_field(:_delete)
    end
    return html
  end
end

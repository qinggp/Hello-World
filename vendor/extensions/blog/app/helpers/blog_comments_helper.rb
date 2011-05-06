# ブログコメントヘルパ
module BlogCommentsHelper
  include Mars::Blog::EntryBodyViewHelper
  include BlogCategoriesViewHelper
  include Mars::UnpublicImageAccessible::Helper

  # 確認画面のボタンURLテーブル生成
  #
  # ==== 引数
  #
  # * blog_comment
  #
  # ==== 戻り値
  #
  # URLテーブル
  def blog_comments_confirm_urls(blog_comment)
    urls =
      if blog_comment.new_record?
        {:form => confirm_before_create_blog_entry_blog_comments_path(@blog_entry, :anchor => blog_comment_anchor_name),
         :clear => blog_entry_path(@blog_entry, :anchor => blog_comment_anchor_name)}
      else
        {:form => confirm_before_update_blog_entry_blog_comments_path(@blog_entry, :id => blog_comment, :anchor => blog_comment_anchor_name),
         :clear => edit_blog_entry_blog_comment_path(@blog_entry, blog_comment, :anchor => blog_comment_anchor_name)}
      end

    return urls
  end

  # 登録／更新画面のボタンURLテーブル生成
  #
  # ==== 引数
  #
  # * blog_comment
  #
  # ==== 戻り値
  #
  # URLテーブル
  def blog_comments_save_urls(blog_comment)
    urls =
      if blog_comment.new_record?
        {:ok => blog_entry_blog_comments_path(@blog_entry), :method => :post}
      else
        {:ok => blog_entry_blog_comment_path(@blog_entry, blog_comment),
         :method => :put}
      end

    return urls
  end

  # コメント投稿者名表示
  def display_blog_comment_user_name(blog_comment)
    if blog_comment.anonymous?
      name = h(blog_comment.user_name)
      if current_user.try(:has_role?, :blog_entry_author, blog_comment.blog_entry) &&
          !blog_comment.email.blank?
        name = mail_to(h(blog_comment.email), name)
      end
      return name + "さん"
    else
      name = link_to_user(blog_comment.user, h(blog_comment.user.name)) + "さん"
      name << "（著者）" if blog_comment.blog_entry.user_id == blog_comment.user_id
      return name
    end
  end

  # ブログコメントアンカ名
  def blog_comment_anchor_name
    "blog_comment"
  end

  # ブログコメントフォーム名表示
  def display_blog_comment_form_name(blog_comment)
    if blog_comment.new_record?
      "コメント送信"
    else
      "コメント編集"
    end
  end

  # ブログデザインの色に応じたスタイルシートを生成
  #
  # ==== 引数
  #
  # blog_pref - ユーザブログ設定
  #
  # ==== 戻り値
  #
  # スタイルシート
  def write_basic_color_style(blog_pref)
    case blog_pref.basic_color_name
    when :green
      basic_color_code = "#c9e49e"
      light_basic_color_code = "#F6F9E9"
    when :blue
      basic_color_code = "#a8c7d5"
      light_basic_color_code = "#eaf2f2"
    when :orange
      basic_color_code = "#fbc593"
      light_basic_color_code = "#fef5e7"
    when :brown
      basic_color_code = "#d7d1a2"
      light_basic_color_code = "#f7f5ea"
    end

    css = <<EOF
.title {
  border-bottom:1px dotted #{basic_color_code};
}
.all_link {
   border-top:1px dotted #{basic_color_code};
}
.blog_entry_title {
  border-top: 1px solid #{basic_color_code};
  border-left: 15px solid #{basic_color_code};
  border-bottom: 1px solid #{basic_color_code};
}
.blog_entry_date {
  border-right: 10px solid #{basic_color_code};
}
.blog_entry_border {
  border-top: 1px dotted #{basic_color_code};
}
.blog_entry_sub_title {
  border-left: 10px solid #{basic_color_code};
  border-bottom: 1px dotted #{basic_color_code};
}
.blog_comment_body {
  border-left: 1px solid #{light_basic_color_code};
}
.blog_comment_info {
  border-top: 2px dotted #{light_basic_color_code};
}
table.content_table_for_wyswyg {
  border:2px solid #{basic_color_code};
}
table.content_table_for_wyswyg .content_table_title {
  background-color: #{light_basic_color_code};
  border:1px solid #{basic_color_code};
}
table.content_table_for_wyswyg th {
  background-color: #{light_basic_color_code};
  border:1px solid #{basic_color_code};
}
table.content_table_for_wyswyg td.data {
  border:1px solid #{basic_color_code};
}
.content_box_bg {
  background-color: #{basic_color_code};
}
table.content_table th {
  background-color: #{light_basic_color_code};
  border:1px solid #{basic_color_code};
}
table.content_table .content_table_title {
  background-color: #{light_basic_color_code};
  border:1px solid #{basic_color_code};
}
table.content_table td {
  border:1px solid #{basic_color_code};
}
EOF
    style = %Q(<style type="text/css">)
    style << css
    style << %Q(</style>)
    return style
  end

  # 去年以降のバックナンバリンク表示
  def prev_year_backnumbers_link(last_date)
    new_year = Date.new(Date.today.year-1, -1)
    if last_date < new_year
      link_to_remote(h(l(new_year, :format => :year_month) + " >> " + l(last_date, :format => :year_month)),
                     :update => "blog_navigation_backnumber",
                     :url => spread_backnumber_user_blog_entries_path(@user), :method => :get)
    end
  end

  # 指定月のブログ記事数
  def backnumber_entry_count(date)
    date = Date.new(date.year, date.month, 1)
    BlogEntry.by_visible(current_user).by_user(@user).
      created_at_greater_than_or_equal_to(date.to_time).
      created_at_less_than(date.next_month.to_time).size
  end

  # バックナンバのDateリスト取得
  def backnumber_dates(last_date)
    dates = []
    date = Date.today
    while(date >= last_date) do
      dates << date
      date = date << 1
    end
    dates
  end

  # 携帯用バックナンバ表示
  def display_backnumber_for_mobile(dates)
    html = ""
    year_months = dates.group_by(&:year)
    year_months.keys.sort_by{|k| -k }.each do |year|
      html << %Q(#{year}年<br/>)
      [4, 8, 12].each do |par_line|
        year_months[year].reverse.select{|m| m.month <= par_line && m.month > par_line-4}.each do |date|
          html << link_to("#{date.month}月", show_calendar_user_blog_entries_path(displayed_user, :date => {:year => year, :month => date.month}))
          html << "（#{backnumber_entry_count(date)}）"
        end
        html << "<br/>"
      end
      html << "<br/>"
    end
    html
  end
end

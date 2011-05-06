# Blog機能UI拡張ヘルパ
#
# blog_extension.rb で ui に部分テンプレートを追加する際、
# 何も指定しなければこのヘルパモジュールを利用します。
#
# メソッド名の名前が衝突する恐れがあるため「blog_」をメソッ
# ド名先頭に付けてください。
module BlogPartHelper

  # プロフィール画面で表示する最近のブログ投稿
  def blog_entries_by_rss_at_profile
    entries = BlogEntry.by_visible(current_user).by_user(displayed_user).
      descend_by_created_at.find(:all, :limit => 10)
    rss_url = displayed_user.preference.blog_preference.rss_url
    unless rss_url.blank?
      entries = BlogEntry.merge_imported_entries_by_rss(rss_url, entries)
    end
    return entries
  end

  # 最新マイブログコメント
  def blog_recent_comments_for_my_entries
    BlogComment.recents_my_blog(current_user, current_user,
      news_show_option_count_select_value("blog_comments_checklist").to_i,
      news_show_option_span_select_value("blog_comments_checklist").to_i.day.ago)
  end

  # コメント記入履歴
  def blog_recent_my_comments
    BlogComment.recents_my_comment(current_user, current_user,
      news_show_option_count_select_value("blog_my_comments_checklist").to_i,
      news_show_option_span_select_value("blog_my_comments_checklist").to_i.day.ago)
  end

  # トモダチ最新ブログ
  def blog_recent_friend_entries
    limit = news_show_option_count_select_value("blog_friend_entries_news").to_i
    day_ago = news_show_option_span_select_value("blog_friend_entries_news").to_i.day.ago
    entries = BlogEntry.by_new_blog_entry_displayed_for_user(current_user).
      by_visible_for_user(current_user, false).recents(limit, day_ago)
    if news_show_option_included_rss?("blog_friend_entries_news")
      current_user.friends.each do |friend|
        entries = BlogEntry.merge_imported_entries_by_rss(
          friend.preference.blog_preference.rss_url,
          entries, :user => friend)
      end
    end
    return entries.take(limit)
  end

  # 最新マイブログ
  def blog_recent_my_entries
    return BlogEntry.user_id_is(current_user.id).
      recents(news_show_option_count_select_value("blog_friend_entries_news").to_i,
        news_show_option_span_select_value("blog_friend_entries_news").to_i.day.ago)
  end
end

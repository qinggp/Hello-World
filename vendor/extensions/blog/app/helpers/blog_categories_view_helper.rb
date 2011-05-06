# ブログカテゴリ表示ヘルパ
module BlogCategoriesViewHelper
  # カテゴリのセレクトボックス要素
  def categories_select_options
    res = BlogCategory.shared_is(true) + BlogCategory.user_id_is(current_user.id)
    return res.map{|r| [r.name, r.id] }
  end

  # カテゴリリンク生成
  def link_for_category(entry)
    return link_to(h(entry.blog_category.name),
             index_for_user_user_blog_entries_path(entry.user,
               :blog_category_id => entry.blog_category_id
           ))
  end
end

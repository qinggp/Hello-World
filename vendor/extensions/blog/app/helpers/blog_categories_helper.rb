# ブログカテゴリ管理ヘルパ
module BlogCategoriesHelper
  
  # 確認画面のForm情報
  def form_params
    if @blog_category.new_record?
      {:url => confirm_before_create_user_blog_categories_path(current_user),
        :model_instance => @blog_category}
    else
      {:url => confirm_before_update_user_blog_categories_path(current_user, :id => @blog_category.id),
        :model_instance => @blog_category}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @blog_category.new_record?
      {:url => user_blog_categories_path(current_user), :method => :post,
        :model_instance => @blog_category}
    else
      {:url => user_blog_category_path(current_user, @blog_category), :method => :put,
        :model_instance => @blog_category}
    end
  end
end

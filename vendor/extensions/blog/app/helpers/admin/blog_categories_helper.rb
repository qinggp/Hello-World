# ブログカテゴリ管理ヘルパ
module Admin::BlogCategoriesHelper
  
  # 確認画面のForm情報
  def form_params
    if @blog_category
      if @blog_category.new_record?
        {:url => confirm_before_create_admin_blog_categories_path(),
          :model_instance => @blog_category}
      else
        {:url => confirm_before_update_admin_blog_categories_path(:id => @blog_category.id),
          :model_instance => @blog_category}
      end
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @blog_category.new_record?
      {:url => admin_blog_categories_path(), :method => :post,
        :model_instance => @blog_category}
    else
      {:url => admin_blog_category_path(@blog_category), :method => :put,
        :model_instance => @blog_category}
    end
  end
end

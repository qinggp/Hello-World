# ページヘルパ
module PagesHelper

  # 確認画面のForm情報
  def form_params
    if @page.new_record?
      {:url => confirm_before_create_pages_path,
        :model_instance => @page}
    else
      {:url => confirm_before_update_pages_path(:id => @page.id),
        :model_instance => @page}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @page.new_record?
      {:url => pages_path, :method => :post,
        :model_instance => @page}
    else
      {:url => page_path(@page), :method => :put,
        :model_instance => @page}
    end
  end
end

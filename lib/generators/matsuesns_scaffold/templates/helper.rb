# <%= controller_class_name %>ヘルパ（FIXME: 日本語名を書く）
module <%= controller_class_name %>Helper
  
  # 確認画面のForm情報
  def form_params
    if @<%= file_name %>.new_record?
      {:url => confirm_before_create_<%= plural_name_with_nesting %>_path,
        :model_instance => @<%= file_name %>}
    else
      {:url => confirm_before_update_<%= plural_name_with_nesting %>_path(:id => @<%= file_name %>.id),
        :model_instance => @<%= file_name %>}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @<%= file_name %>.new_record?
      {:url => <%= plural_name_with_nesting %>_path, :method => :post,
        :model_instance => @<%= file_name %>}
    else
      {:url => <%= singular_name_with_nesting %>_path(@<%= file_name %>), :method => :put,
        :model_instance => @<%= file_name %>}
    end
  end
end

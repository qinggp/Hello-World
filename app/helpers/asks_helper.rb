# お問い合わせヘルパ
module AsksHelper
  
  # 確認画面のForm情報
  def form_params
    {:url => confirm_before_create_asks_path,
      :model_instance => @user}
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    {:url => asks_path, :method => :post,
      :model_instance => @user}
  end
end

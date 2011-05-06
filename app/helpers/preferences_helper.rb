# ユーザ設定ヘルパ
module PreferencesHelper
  
  # 確認画面のFrom情報生成
  def form_params
    if @preference.new_record?
      {:url => confirm_before_create_preferences_path,
        :model_instance => @preference}
    else
      {:url => confirm_before_update_preferences_path(:id => @preference),
        :model_instance => @preference}
    end
  end

  # 登録／更新画面のFrom情報生成
  def confirm_form_params
    if @preference.new_record?
      {:url => preferences_path, :method => :post,
        :model_instance => @preference}
    else
      {:url => preference_path(@preference), :method => :put,
        :model_instance => @preference}
    end
  end
end

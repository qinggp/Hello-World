# SNS設定ヘルパ
module Admin::SnsConfigsHelper
  
  # 確認画面のForm情報
  def form_params
    if @sns_config
      {:url => confirm_before_update_admin_sns_config_path(:id => @sns_config.id),
        :model_instance => @sns_config}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
      {:url => admin_sns_config_path(@sns_config), :method => :put,
        :model_instance => @sns_config}
  end
end

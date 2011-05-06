# 招待機能ヘルパ
module InvitesHelper
  
  # 確認画面のForm情報
  def form_params
    if @invite.new_record?
      {:url => confirm_before_create_invites_path,
        :model_instance => @invite}
    else
      {:url => confirm_before_update_invites_path(:id => @invite.id),
        :model_instance => @invite}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @invite.new_record?
      {:url => invites_path, :method => :post,
        :model_instance => @invite}
    else
      {:url => invite_path(@invite), :method => :put,
        :model_instance => @invite}
    end
  end
end

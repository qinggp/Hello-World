# コミュニティリンクヘルパ
module CommunityLinkagesHelper
  include Mars::Community::CommonHelper

  # 確認画面のForm情報
  def form_params
    if @community_linkage.new_record?
      {:url => confirm_before_create_community_linkages_path(:community_id => @community),
        :model_instance => @community_linkage}
    else
      {:url => confirm_before_update_community_linkages_path(:id => @community_linkage.id, :community_id => @community),
        :model_instance => @community_linkage}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    {:url => community_linkages_path(:community_id => @community), :method => :post,
      :model_instance => @community_linkage}
  end
end

# コミュニティカテゴリヘルパ
module CommunityMapCategoriesHelper
  include Mars::Community::CommonHelper

  # 確認画面のForm情報
  def form_params
    if @community_map_category.new_record?
      {:url => confirm_before_create_community_map_categories_path,
        :model_instance => @community_map_category}
    else
      {:url => confirm_before_update_community_map_categories_path(:id => @community_map_category.id),
        :model_instance => @community_map_category}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @community_map_category.new_record?
      {:url => community_map_categories_path, :method => :post,
        :model_instance => @community_map_category}
    else
      {:url => community_map_category_path(:id => @community_map_category, :community_id => params[:community_id]), :method => :put,
        :model_instance => @community_map_category}
    end
  end
end

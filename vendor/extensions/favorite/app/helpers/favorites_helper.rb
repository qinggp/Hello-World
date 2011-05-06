# お気に入り機能ヘルパ
module FavoritesHelper
  
  # 確認画面のForm情報
  def form_params
    {:url => confirm_before_update_favorites_path(:id => @favorite.id),
      :model_instance => @favorite}
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @favorite.new_record?
      {:url => favorites_path, :method => :post,
        :model_instance => @favorite}
    else
      {:url => favorite_path(@favorite), :method => :put,
        :model_instance => @favorite}
    end
  end
end

# コミュニティマーカーヘルパ
module CommunityMarkersHelper
  include Mars::Community::CommonHelper

 alias_method :form_notation, :form_notation_with_attachment

  # 確認画面のForm情報
  def form_params
    if @community_marker.new_record?
      {:url => confirm_before_create_new_community_marker_path, :multipart => true,
       :model_instance => @community_marker, :name => "fmSubmit"}
    else
      {:url => confirm_before_update_community_marker_path(:id => @community_marker),
        :model_instance => @community_marker, :multipart => true, :name => "fmSubmit"}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @community_marker.new_record?
      {:url => community_markers_path, :method => :post,
        :model_instance => @community_marker}
    else
      {:url => community_marker_path(:id => @community_marker), :method => :put,
        :model_instance => @community_marker}
    end
  end

  # Formのタイトル
  def form_title
    if @community_marker.new_record?
      return "マーカー作成"
    else
      return "マーカー修正"
    end
  end

  # フォーム画面で表示する注意書き
  def form_notation
    notation = font_red("※") + "は必須項目です。" + "<br />"
    notation += "[ファイル添付のご注意] 添付できるファイルサイズは全て合わせて #{font_red('2MB')} までです。"
  end

  def select_map_categories(community, selected_value)
    values = community.map_categories.map do |category|
      [category.name, category.id]
    end
    values.unshift(["選択なし", nil])

    select(:community_marker, :community_map_category_id,
           options_for_select(values, selected_value))
  end

  # マップ表示時に、番号による色を指定する
  def category_color(number)
    colors = %w(red blue lime yellow aqua olive pink linen silver purple)
    colors[number] || "red"
  end
end

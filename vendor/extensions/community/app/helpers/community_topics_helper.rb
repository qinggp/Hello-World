# コミュニティトピックヘルパ
module CommunityTopicsHelper
  include Mars::Community::CommonHelper

  # 確認画面のForm情報
  def form_params
    if @community_topic.new_record?
      {:url => confirm_before_create_new_community_topic_path, :multipart => true,
        :model_instance => @community_topic}
    else
      {:url => confirm_before_update_community_topic_path(:id => @community_topic),
        :model_instance => @community_topic, :multipart => true}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @community_topic.new_record?
      {:url => community_topics_path, :method => :post,
        :model_instance => @community_topic}
    else
      {:url => community_topic_path(:id => @community_topic.id), :method => :put,
        :model_instance => @community_topic}
    end
  end

  # Formのタイトル
  def form_title
    if @community_topic.new_record?
      return "トピック作成"
    else
      return "トピック修正"
    end
  end

  # フォーム画面で表示する注意書き
  def form_notation
    notation = font_red("※") + "は必須項目です。" + "<br />"
    notation += "[ファイル添付のご注意] 添付できるファイルサイズは全て合わせて #{font_red('2MB')} までです。"
  end

  # フォーム画面で表示する注意書き（携帯用）
  def mobile_form_notation
    font_red("※") + "は必須項目です。"
  end
end

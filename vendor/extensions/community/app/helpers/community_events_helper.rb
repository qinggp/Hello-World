module CommunityEventsHelper
  include Mars::Community::CommonHelper

  # 登録・編集画面のForm情報
  def form_params
    if @community_event.new_record?
      {:url => confirm_before_create_new_community_event_path, :multipart => true,
       :model_instance => @community_event, :name => "fmSubmit"}
    else
      {:url => confirm_before_update_community_event_path(:id => @community_event.id), :multipart => true,
       :model_instance => @community_event, :name => "fmSubmit"}
    end
  end

  # 確認画面のForm情報
  def confirm_form_params
    if @community_event.new_record?
      {:url => community_events_path,
       :model_instance => @community_event, :method => :post}
    else
      {:url => community_event_path(:id => @community_event),
       :model_instance => @community_event, :method => :put}
    end
  end

  # Formのタイトル
  def form_title
    if @community_event.new_record?
      "イベント追加"
    else
      "イベント修正"
    end
  end

  # フォーム画面で表示する注意書き
  def form_notation
    notation = font_red("※") + "は必須項目です。" + "<br />"
    notation += "[ファイル添付のご注意] 添付できるファイルサイズは全て合わせて #{font_red('2MB')} までです。"
  end
end

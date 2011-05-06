# コミュニティ返信ヘルパ
module CommunityRepliesHelper
  include Mars::Community::CommonHelper

  alias_method :form_notation, :form_notation_with_attachment

  # 登録・編集画面のForm情報
  def form_params
    thread_type = @community_reply.thread.kind.underscore
    if @community_reply.new_record?
      {:url => send("confirm_before_create_#{thread_type}_replies_path", "#{thread_type}_id".to_sym => @community_reply.thread.id), :multipart => true,
        :model_instance => @community_reply}
    else
      {:url => send("confirm_before_update_#{thread_type}_replies_path", :id => @community_reply, "#{thread_type}_id".to_sym => @community_reply.thread.id),
        :multipart => true, :model_instance => @community_reply}
    end
  end

  # 確認画面のForm情報
  def confirm_form_params
    thread_type = @community_reply.thread.kind.underscore
    if @community_reply.new_record?
      {:url => send("#{thread_type}_replies_path", "#{thread_type}_id".to_sym => @community_reply.thread.id),
        :method => :post, :model_instance => @community_reply}
    else
      {:url => send("#{thread_type}_reply_path", :id => @community_reply, "#{thread_type}_id".to_sym => @community_reply.thread.id),
        :method => :put, :model_instance => @community_reply}
    end
  end

  def form_title
    if @community_reply.new_record?
      message = "このメッセージに返信する"
    else
      message = "この書き込みを修正する"
    end
  end
end

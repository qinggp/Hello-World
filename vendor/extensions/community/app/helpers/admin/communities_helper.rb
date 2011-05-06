# コミュニティ管理ヘルパ
module Admin::CommunitiesHelper
  include Mars::Community::CommonHelper
  include Admin::ContentsHelper

  def form_params
    if @community
      {:url => confirm_before_update_admin_communities_path(:id => @community.id),
        :model_instance => @community, :multipart => true

        }
    end
  end

  def confirm_form_params
      {:url => admin_community_path(@community), :method => :put,
        :model_instance => @community}
  end

  def options_for_select_with_community_categories(community_category_id)
    sub_categories = CommunityCategory.sub_categories
    list = sub_categories.map do |sub_category|
      [sub_category.name_with_parent, sub_category.id]
    end.unshift ["選択なし", ""]

    options_for_select(list, community_category_id.to_i)
  end

  def options_for_select_with_officials(selected_official)
    list = []
    Community::OFFICIALS.each_with_index do |official, index|
      list.push([t(:official, :scope => [:community])[official], index])
    end
    options_for_select(list, selected_official)
  end

  def form_title
    case params[:action]
    when "edit", "confirm_before_update"
      "コミュニティ管理"
    end
  end

  # コミュニティの画像へのパスを返す
  def admin_community_image_path(community, image_type = nil)
    url_for(:controller => "communities",
            :action => :show_unpublic_image,
            :community_id =>community.id,
            :id => community.id,
            :image_type => image_type)
  end

  # 確認画面の添付画像表示
  def admin_confirm_community_image(community)
    image_link, image, update_message = "", "", ""

    # 更新時に、画像がどう変化したか
    unless community.new_record?
      if community.image?
        if community.image_changed?
          update_message = "(修正)"
        else
          update_message = "(修正無し)"
        end
      elsif community.image_changed?
        update_message = "(削除)"
      end
    end

    if community.image
      image_link << theme_image_tag(icon_name_by_extname(community.image))
      image_link << h(File.basename(community.image))
      if community.new_record? || community.image_changed?
        image << admin_temp_community_image(community.image_temp)
      elsif !community.image_changed?
        image << admin_community_image(community)
      end
    elsif community.image_changed? && !community.new_record?
      # 画像が削除されようとしているとき
      old_community = Community.find(community.id)
      image_link << theme_image_tag(icon_name_by_extname(old_community.image))
      image_link << h(File.basename(old_community.image))
      image << admin_community_image(community)
    end
    image_link + update_message + "<br />" + image
  end

  # コミュニティの仮の画像（小さいの）と元画像へのリンク
  def admin_temp_community_image(image_temp, image_type = "medium")
    link_to(theme_image_tag(show_unpublic_image_temp_admin_communities_path(:image_temp => image_temp, :image_type => image_type)),
            show_unpublic_image_temp_admin_communities_path(:image_temp => image_temp))
  end

  # コミュニティの画像（小さいの）と元画像へのリンク
  def admin_community_image(community, image_type = "medium")
    link_to(theme_image_tag(show_unpublic_image_community_path(:community_id => community.id, :id => community.id, :image_type => image_type)),
            show_unpublic_image_community_path(:community_id => community.id, :id => community.id))
  end

  # コミュニティ変更画面での画像の表示
  def admin_form_attachment_file(community)
    display_attachment_file(community,
      :attachment_path =>
        show_unpublic_image_community_path(:community_id => community.id, :id => community.id, :image_type => "medium"),
      :original_attachment_path =>
        show_unpublic_image_community_path(:community_id => community.id, :id => community.id)
      )
  end

  # typeに対応したパスを返す
  def path_corresponding_to_kind(community_topic)
  kind = community_topic.kind || community_topic.attributes["kind"]
  case kind
    when 'CommunityTopic'
      link_tag = link_to('URL', new_community_topic_reply_path(:community_topic_id => community_topic.id))
    when 'CommunityEvent'
      link_tag = link_to('URL', new_community_event_reply_path(:community_event_id => community_topic.id))
    when 'CommunityMarker'
      link_tag = link_to('URL', new_community_marker_reply_path(:community_marker_id => community_topic.id))
    when 'CommunityReply'
      community_replies = CommunityReply.find(community_topic.id)
      case community_replies.thread_type
      when 'CommunityTopic'
        link_tag = link_to('URL', new_community_topic_reply_path(:community_topic_id => community_replies.thread_id, :parent_id => community_replies.id))
      when 'CommunityEvent'
        link_tag = link_to('URL', new_community_event_reply_path(:community_event_id => community_replies.thread_id, :parent_id => community_replies.id))
      when 'CommunityMarker'
        link_tag = link_to('URL', new_community_marker_reply_path(:community_marker_id => community_replies.thread_id, :parent_id => community_replies.id))
      end
    end
    return link_tag
  end

  # ブログ、イベントの書き込みに対する添付の表示
  def display_write_attachment(entry)
    html = ""
    if entry.class.to_s == 'CommunityEvent'
      entry.attachments.each do |attachment|
        option = {:id => attachment.thread_id, :community_thread_attachment_id => attachment.id}
          html << display_attachment_file(attachment,
                   :attachment_path => show_unpublic_image_community_event_path(entry.community_id, option.merge(:image_type => "thumb")),
                   :original_attachment_path => show_unpublic_image_community_event_path(entry.community_id, option)
          )
      end
    end
    return html
  end

  # トピック、イベント、マーカー、コメント書き込みに対応する添付を表示する
  def attachments_corresponding_to_topic(topic)
    html = ""
    case topic.parent_thread_type
    when 'CommunityThread'
      option = {:id => topic.id}
      attachments = CommunityThreadAttachment.find(:all, :conditions => ['thread_id = ?', topic.id], :order => 'position asc')
      attachments.each do |attachment|
        option.merge!(:community_thread_attachment_id => attachment.id)
        case topic.thread_type
        when 'CommunityEvent'
          attachment_path = Proc.new{show_unpublic_image_community_event_path(topic.community_id, option.merge(:image_type => "thumb"))}
          original_attachment_path = Proc.new{show_unpublic_image_community_event_path(topic.community_id, option)}
        when 'CommunityTopic'
          attachment_path = Proc.new{show_unpublic_image_community_topic_path(topic.community_id, option.merge(:image_type => "thumb"))}
          original_attachment_path = Proc.new{show_unpublic_image_community_topic_path(topic.community_id, option)}
        when 'CommunityMarker'
          attachment_path = Proc.new{show_unpublic_image_community_marker_path(topic.community_id, option.merge(:image_type => "thumb"))}
          original_attachment_path = Proc.new{show_unpublic_image_community_marker_path(topic.community_id, option)}
        end
        html << display_attachment_file(attachment,
                  :attachment_path => attachment_path.call,
                  :original_attachment_path => original_attachment_path.call
        )
      end
    when 'CommunityReply'
      attachments = CommunityReplyAttachment.find(:all, :conditions => ['community_reply_id = ?', topic.id], :order => 'position')
      attachments.each do |attachment|
        option = {:id => topic.id, :community_reply_attachment_id => attachment.id}
        case topic.thread_type
        when 'CommunityEvent'
          attachment_path = Proc.new{show_unpublic_image_community_event_reply_path(topic.thread_id, option.merge(:image_type => "thumb"))}
          original_attachment_path = Proc.new{show_unpublic_image_community_event_reply_path(topic.thread_id, option)}
        when 'CommunityTopic'
          attachment_path = Proc.new{show_unpublic_image_community_topic_reply_path(topic.thread_id, option.merge(:image_type => "thumb"))}
          original_attachment_path = Proc.new{show_unpublic_image_community_topic_reply_path(topic.thread_id, option)}
        when 'CommunityMarker'
          attachment_path = Proc.new{show_unpublic_image_community_marker_reply_path(topic.thread_id, option.merge(:image_type => "thumb"))}
          original_attachment_path = Proc.new{show_unpublic_image_community_marker_reply_path(topic.thread_id, option)}
        end
        html << display_attachment_file(attachment,
                  :attachment_path => attachment_path.call,
                  :original_attachment_path => original_attachment_path.call
        )
      end
    end
    return html
  end

  # ファイル一覧の添付の表示
  # ==== 引数
  # * attachment
  def display_attachment(attachment)
    html = ""
    case attachment.class.to_s
    when 'CommunityThreadAttachment'
      option = {:community_thread_attachment_id => attachment.id, :id => attachment.thread_id}
      case attachment.thread.kind
      when 'CommunityEvent'
        attachment_path = Proc.new{show_unpublic_image_community_event_path(attachment.thread.community_id, option.merge(:image_type => "thumb"))}
        original_attachment_path = Proc.new{show_unpublic_image_community_event_path(attachment.thread.community_id, option)}
      when 'CommunityTopic'
        attachment_path = Proc.new{show_unpublic_image_community_topic_path(attachment.thread.community_id, option.merge(:image_type => "thumb"))}
        original_attachment_path = Proc.new{show_unpublic_image_community_topic_path(attachment.thread.community_id, option)}
      when 'CommunityMarker'
        attachment_path = Proc.new{show_unpublic_image_community_marker_path(attachment.thread.community_id, option.merge(:image_type => "thumb"))}
        original_attachment_path = Proc.new{show_unpublic_image_community_marker_path(attachment.thread.community_id, option)}
      end
    end
    html << display_attachment_file(attachment,
             :attachment_path => attachment_path.call,
             :original_attachment_path => original_attachment_path.call
            )
    return html
  end

  # コミュニティトピックファイル一覧でのファイルの表示
  # 添付ファイルのリンク先を正しく取得する
  def view_topic_attachment(attachment)
    html = ""
    case attachment.parent_thread_type
    when 'CommunityThread'
      conditions = ['id = ?', attachment.thread_id]
      option = {:id => attachment.thread_id, :community_thread_attachment_id => attachment.id}
      case attachment.thread.kind
      when 'CommunityTopic'
        community_id = CommunityTopic.find(:first, :conditions => conditions, :select => 'community_id').community_id
        attachment_path = Proc.new{show_unpublic_image_community_topic_path(community_id, option.merge(:image_type => "thumb"))}
        original_attachment_path = Proc.new{show_unpublic_image_community_topic_path(community_id, option)}
      when 'CommunityEvent'
        community_id = CommunityEvent.find(:first, :conditions => conditions, :select => 'community_id').community_id
        attachment_path = Proc.new{show_unpublic_image_community_event_path(community_id, option.merge(:image_type => "thumb"))}
        original_attachment_path = Proc.new{show_unpublic_image_community_event_path(community_id, option)}
      when 'CommunityMarker'
        community_id = CommunityMarker.find(:first, :conditions => conditions, :select => 'community_id').community_id
        attachment_path = Proc.new{show_unpublic_image_community_marker_path(community_id, option.merge(:image_type => "thumb"))}
        original_attachment_path = Proc.new{show_unpublic_image_community_marker_path(community_id, option)}
      end
    when 'CommunityReply'
      option = {:id => attachment.community_reply_id, :community_reply_attachment_id => attachment.id}
      case attachment.thread_type
      when 'CommunityTopic'
        attachment_path = Proc.new{show_unpublic_image_community_topic_reply_path(attachment.thread_id, option.merge(:image_type => "thumb"))}
        original_attachment_path = Proc.new{show_unpublic_image_community_topic_reply_path(attachment.thread_id, option)}
      when 'CommunityEvent'
        attachment_path = Proc.new{show_unpublic_image_community_event_reply_path(attachment.thread_id, option.merge(:image_type => "thumb"))}
        original_attachment_path = Proc.new{show_unpublic_image_community_event_reply_path(attachment.thread_id, option)}
      when 'CommunityMarker'
        attachment_path = Proc.new{show_unpublic_image_community_marker_reply_path(attachment.thread_id, option.merge(:image_type => "thumb"))}
        original_attachment_path = Proc.new{show_unpublic_image_community_marker_reply_path(attachment.thread_id, option)}
      end
    end
    html << display_attachment_file(attachment,
           :attachment_path => attachment_path.call,
           :original_attachment_path => original_attachment_path.call
            )
    return html
  end
end

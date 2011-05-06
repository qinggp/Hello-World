module CommunitiesHelper
  include Mars::Community::CommonHelper

  # 登録・編集画面のForm情報
  def form_params
    if @community.new_record?
      {:url => confirm_before_create_new_community_path,
       :model_instance => @community, :multipart => true}
    else
      {:url => confirm_before_update_community_path(:id => @community.id),
       :model_instance => @community, :multipart => true}
    end
  end

  # 確認画面のForm情報
  def confirm_form_params
    if @community.new_record?
      {:url => communities_path, :model_instance => @community,
       :method  => :post}
    else
      {:url => community_path(@community), :model_instance => @community,
       :method => :put}
    end
  end

  # 登録・編集画面で表示する注意文
  def form_notation
    return <<-HTML
      <font color="red">※</font>は必須項目です。<br />
      [ファイル添付のご注意] 添付できるファイルサイズは全て合わせて <font color="red">300KB</font> までです。
    HTML
  end

  # Formのタイトル
  def form_title
    case params[:action]
    when "new", "confirm_before_create", "create"
      "コミュニティ作成"
    when "edit", "confirm_before_update", "update"
      "コミュニティ修正"
    end
  end

  def options_for_select_with_community_categories(community_category_id)
    sub_categories = CommunityCategory.sub_categories
    list = sub_categories.map do |sub_category|
      [sub_category.name_with_parent, sub_category.id]
    end.unshift ["選択して下さい", ""]

    options_for_select(list, community_category_id.to_i)
  end

  def options_for_select_using_category_serach(community_category_id)
    sub_categories = CommunityCategory.sub_categories
    list = sub_categories.map do |sub_category|
      [sub_category.name, sub_category.id]
    end.unshift ["指定なし", nil]

    options_for_select(list, community_category_id.to_i)
  end

  # トピックの画像を表示する
  def topic_image(community, options = { })
    str = theme_image_tag("community/comm_topic.gif")
    if options[:number]
      str += community.topics.size.to_s
    end
    str
  end

  # イベントの画像を表示する
  def event_image(community, options = { })
    str = theme_image_tag("community/comm_event.gif")
    if options[:number]
      str += community.events.size.to_s
    end
    str
  end

  # マーカーの画像を表示する
  def marker_image(community, options = { })
    str = theme_image_tag("map_pin.png")
    if options[:number]
      str += community.markers.size.to_s
    end
    str
  end

  # コミュニティをソートするためのリンクパラメータの生成
  # kind: ソート対象を表す数字
  def parameter_for_order_link(kind)
    figure = ""
    asc_or_desc = CommunitiesController::DESC

    if params[:order] && params[:order][:kind].to_i == kind
      # 現在のソート対象と一致しているとき
      case params[:order][:asc_or_desc].to_i
      when CommunitiesController::ASC
        figure =  "▲"
        asc_or_desc = CommunitiesController::DESC
      when CommunitiesController::DESC
        figure = "▼"
        asc_or_desc = CommunitiesController::ASC
      else
        figure = "▼"
        asc_or_desc = CommunitiesController::ASC
      end
    elsif !params[:order] && kind.to_i == CommunitiesController::POSTED_AT
      # デフォルトのソート
      figure = "▼"
    end

    order_parameter = {:order => {:kind => kind, :asc_or_desc => asc_or_desc}}

    yield(order_parameter) if block_given?
    concat figure unless figure.blank?
  end

  # 各トピックやマーカー、イベントのトップページへのpathを返す
  def path_to_thread(thread)
    send("#{thread.class.to_s.underscore.pluralize}_path", :community_id => thread.community_id)
  end

  # 確認画面の添付画像表示
  def confirm_community_image(community)
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
        image << temp_community_image(community.image_temp)
      elsif !community.image_changed?
        image << community_image(community)
      end
    elsif community.image_changed? && !community.new_record?
      # 画像が削除されようとしているとき
      old_community = Community.find(community.id)
      image_link << theme_image_tag(icon_name_by_extname(old_community.image))
      image_link << h(File.basename(old_community.image))
      image << community_image(community)
    end
    image_link + update_message + "<br />" + image
  end

  # コミュニティの仮の画像（小さいの）と元画像へのリンク
  def temp_community_image(image_temp, image_type = "medium")
    link_to(theme_image_tag(show_unpublic_image_temp_communities_path(:image_temp => image_temp, :image_type => image_type)),
            show_unpublic_image_temp_communities_path(:image_temp => image_temp))
  end

  # コミュニティの画像（小さいの）と元画像へのリンク
  def community_image(community, image_type = "medium")
    link_to(theme_image_tag(show_unpublic_image_community_path(:community_id => community.id, :image_type => "medium")),
            show_unpublic_image_community_path(:community_id => community.id))
  end

  # コミュニティをトモダチに紹介するメッセージの件名
  def subject_for_invite_friend
    "#{current_user.name}さんからコミュニティ紹介メッセージが届いています"
  end

  private
  def community_image_and_comment(community)
    content_tag(:table) do
      table = ""
      table << content_tag(:tr) do
        content_tag(:td) do
          link_to(:action => :show, :id => community.id) do
            theme_image_tag(community_image_path(community, "thumb"), :width => 76)
          end
        end
      end
      table << content_tag(:tr) do
        content_tag(:td) do
          link_to(h(community.comment), :action => :show, :id => community.id)
        end
      end
    end
  end
end

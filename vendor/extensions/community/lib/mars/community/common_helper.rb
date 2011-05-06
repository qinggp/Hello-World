# 拡張機能コミュニティで共通で使用するヘルパ
module Mars::Community::CommonHelper
  include ActionView::Helpers

  # 添付ファイルのサイズ制限を付け加えたフォーム注意書き
  def form_notation_with_attachment
    notation = font_red("※") + "は必須項目です。" + "<br />"
    notation += "[ファイル添付のご注意] 添付できるファイルサイズは全て合わせて #{font_red('2MB')} までです。"
  end

  # replies_controllerが、どのタイプのスレッド（トピック、マーカー、イベント）
  # を扱っているかでパスが異なるので、ここで吸収する
  def reply_path_by_thread_type(thread, options = {})
    named_root = thread.class.to_s.underscore
    prefix = options.delete(:prefix)
    path = [prefix, named_root, "reply_path"].compact.join("_")
    options.update("#{named_root}_id".to_sym => thread.id)
    send(path, options)
  end

  def font_red(str)
    %Q(<font color="red">#{str}</font>)
  end

  # 登録・編集画面の添付画像表示（画像用のモデルが別にある場合）
  def form_attachment_image(attachment)
    unless attachment.new_record?
      return display_attachment_file(attachment, :image_type => "thumb", :form => true) + "<br />"
    end
  end

  # 確認画面の添付画像表示（画像用のモデルが別にある場合）
  def confirm_attachment_image(form, attachment)
    html = ""
    if attachment.new_record?
      if attachment.image
        html << display_temp_attachment_file(attachment, :image_type => "thumb")
      else
        html << form.hidden_field(:_delete, :value => "1")
      end
    else
      html << "（削除）" if attachment._delete
      html << "（修正）" if attachment.image_changed?
      if attachment.image_changed?
        html << display_temp_attachment_file(attachment, :image_type => "thumb")
      else
        html << display_attachment_file(attachment, :image_type => "thumb",
                                        :form => true)
      end
      html << form.hidden_field(:_delete)
    end
    return html
  end

  # イベント、マーカー、トピック、返信の添付ファイルを異なるコントローラから表示する際のURL
  def url_for_attachment(attachment, options={})
    if defined?(attachment.thread)
      url_for({:controller => attachment.thread.class.to_s.pluralize.underscore,
                :action => :show_unpublic_image,
                :id => attachment.thread.id,
                :community_id => attachment.thread.community_id,
                :community_thread_attachment_id => attachment.id}.merge(options))
    elsif defined?(attachment.reply)
      url_for({:controller => attachment.reply.class.to_s.pluralize.underscore,
                :action => :show_unpublic_image,
                :id => attachment.reply.id,
                "#{attachment.reply.thread.class.to_s.underscore}_id" => attachment.reply.thread.id,
                :community_reply_attachment_id => attachment.id}.merge(options))
    end
  end

  # テーブルの要素としてコミュニティを表示する際に使用する
  def display_community_on_table(community, options = { })
    html = ""
    if options[:admin]
      html << content_tag(:div) do
        theme_image_tag("community/comm_owner.gif", :size => "30x12")
      end
    end
    html << content_tag(:div) do
      link_to(theme_image_tag(community_image_path(community, options[:image_type]),
                        :width => options[:width]),
              community_path(community))
    end
    html << content_tag(:div, :style => "width: 70px;") do
      link_to(h(community.name) + "(#{community.members.count})", community_path(community))
    end
  end

  # メンバーをテーブルの要素として表示する際に使用する
  def display_member_on_table(user, community, options = { })
    html = ""
    html << content_tag(:div) do
      div = ""
      div << theme_image_tag("community/comm_owner.gif") if options[:admin]
      div << link_to_user(user, display_face_photo(user.face_photo, :width => options[:width], :height => options[:height]))
    end
    html << content_tag(:div) do
      div = ""
      friend_count = "(#{user.friends.size})" if options[:enabled_friend_count]
      div << theme_image_tag("invite.png") if options[:sub_admin]
      div << link_to_user(user, h(community.member_name_with_suffix(user)) + "#{friend_count}")
    end
  end

  # コミュニティの画像へのパスを返す
  # コミュニティに画像が無ければ、noimage.gifを返す
  def community_image_path(community, image_type = nil)
    if community.image
      url_for(:action => :show_unpublic_image, :community_id =>community.id,
              :controller => :communities,
              :id => community.id,  :image_type => image_type)
    else
      "noimage.gif"
    end
  end

  # ナビゲーション上のコミュニティイメージ表示
  def community_image_from_navigation(community)
    if community.image
      theme_image_tag(url_for(:action => :show_unpublic_image,
                        :community_id =>community.id,
                        :id => community.id,  :image_type => :medium))
    else
      theme_image_tag("noimage.gif", :width => 100, :height => 100)
    end
  end

  # コミュニティリンクの画像へのパスを返す
  # 外部コミュニティは全てoutlink.gifを返す
  def community_linkage_image_path(linkage, image_type = "thumb")
    case linkage.kind
    when "CommunityOuterLinkage"
      "community/outlink.png"
    when "CommunityInnerLinkage"
      community_image_path(linkage.inner_link, image_type)
    else
      "noimage.gif"
    end
  end

  # テーブルの要素としてコミュニティリンクを表示する際に使用する
  def display_community_link_on_table(linkage, view, options = { })
    html = ""

    html << content_tag(:div) do
      link_to(theme_image_tag(community_linkage_image_path(linkage, options[:image_type]),
                        :width => options[:width]),
              linkage.url(view))
    end
    html << content_tag(:div) do
      link_to(h(linkage.name) + linkage.icon(view), linkage.url(view))
    end
  end

  # 返信作成用URLを返す
  # community_replyへの返信は、parent_idを付加する
  def polymorphic_url_on_creating_reply(model, options={})
    if model.class.to_s == "CommunityReply"
      thread_id_name = "#{model.thread.kind.underscore}_id"
      thread_id = model.thread.id
      options = {:parent_id =>  parent_id = model.id}
    else
      thread_id_name = "#{model.kind.underscore}_id"
      thread_id = model.id
    end
    new_community_reply_path(options.merge(thread_id_name => thread_id))
  end

  # スレッド、及びそれへの返信をツリー表示する際のフォーマット
  # 返信でかつ削除済みの場合、内容は表示しない
  def display_comment_tree_format(thread_or_reply)
    if thread_or_reply.class == CommunityReply && thread_or_reply.deleted
      %Q(<span style="color: rgb(153, 153, 153); font-style: italic;">削除済み</span>)
    else
      link_to(h(thread_or_reply.title), polymorphic_url_on_creating_reply(thread_or_reply)) + " - "  +
        h(l(thread_or_reply.created_at, :format => :default_year_month_date)) +
        " (#{h(thread_or_reply.community.member_name(thread_or_reply.author))})"
    end
  end

  # スレッドに対する返信をツリー構造で表示する
  def display_comment_tree(thread, parent_id = nil)
    CommunityReply.thread_id_is(thread.id).parent_id_null.map do |reply|
      content_tag(:ul) { display_reply(reply, parent_id) }
    end.join("\n")
  end

  # 返信文を表示するとき、引用を表す行を強調表示する
  def display_quote_content(str)
    str = h str
    str.gsub!(/^(&gt; [^\r^\n]*)/) { "<font color=\"blue\">#{$1}</font>" }
    str.gsub(/\r\n|\r|\n/, "<br />")
  end

  # ページのタイトル表示
  # 特定のコミュニティを見ているのであれば、コミュニティ名が付加するので、ここでapplication_helperにある同名のメソッドを上書きする
  def page_title
    return nil if @title_off
    title = @title
    full_controller_name = controller.class.name.gsub(/Controller$/, '').underscore.gsub("/", ".")

    community_name = @community.try(:name)

    # NOTE: raiseオプションを指定するとkeyが見つからなかったときに例外が発生する
    page_title ||= (I18n.t("page_titles.#{full_controller_name}.#{action_name}", :raise => true) rescue nil)
    page_title ||= I18n.t("page_titles.#{full_controller_name}_title") + t("page_titles.defaults.#{action_name}")
    title ||= [community_name, page_title].compact.join(" - ")
    h(title)
  end
  alias :page_title_mobile :page_title


  private
  def display_reply(reply, parent_id)
    class_name = (parent_id == reply.id) ? "target" : "sub"
    if reply.children.blank?
      content_tag(:li, :class => class_name) do
        display_comment_tree_format(reply)
      end
    else
      li = ""
      li << content_tag(:li, :class => class_name) do
        display_comment_tree_format(reply)
      end
      li << reply.children.map do |child|
        content_tag(:ul) do
          display_reply(child, parent_id)
        end
      end.join("\n")
    end
  end
end

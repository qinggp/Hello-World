# コミュニティのスレッドへの返信管理
class CommunityRepliesController < ApplicationController
  include Mars::UnpublicImageAccessible
  include Mars::Community::CommonController

  unpublic_image_accessible :model_name => :community_reply_attachment

  layout "communities"

  with_options :redirect_to => :community_replies_url do |con|
    con.verify :params => "id", :only => %w(show destroy confirm_before_update)
    con.verify :params => "community_reply",
      :only => %w(confirm_before_create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  before_filter :load_thread_and_set_community

  # 編集・削除できる権限かチェックする。
  # NOTE: editは返信を表示画面としても使用しているので、ここでの制限はかけない
  edit_or_destroy_actions = %w(confirm_before_update update confirm_before_destroy destroy)
  before_filter :verify_reply_editable_or_destroyable,
                :only => edit_or_destroy_actions

  # 作成できる権限かチェックする。
  create_actions = %w(new confirm_before_create create)
  before_filter :verify_reply_createable, :only => create_actions

  access_control do
    member_actions = %w(index quote_content)
    allow logged_in, :to => member_actions

    # コミュニティの公開範囲に応じたアクセス制限
    allow :community_sub_admin, :community_admin, :community_general, :of => :community, :except => member_actions
    allow anonymous, :if => :anoymous_viewable?, :except => member_actions
    allow logged_in, :if => :login_user_viewable?, :except => member_actions

    # 返信が論理削除されているときは、該当レコードは操作できない
    deny all, :if => :deleted_reply?, :to => edit_or_destroy_actions + %w(show)
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    respond_to do |format|
      format.atom do
        if params[:community_id]
          # コミュニティ指定によるコメントの取得
          sql = Community.sql_for_comments(current_user, :id => params[:community_id].to_i)
          @feed_title = Community.find(params[:community_id]).name
        elsif params[:topic_id]
          # トピック指定によるコメントの取得
          sql = Community.sql_for_comments(current_user, :topic_id => params[:topic_id].to_i)
          @feed_title = CommunityTopic.find(params[:topic_id]).title
        else
          # ログインユーザの所属するコミュニティのトピック＋返信を取得
          sql = Community.sql_for_comments(current_user)
          @feed_title = "コミュニティコメント一覧"
        end

        @page = params[:page] ? params[:page].to_i : 1
        @count = params[:count]? params[:count].to_i : 20
        @comments = CommunityReply.paginate_by_sql(sql,
                                                   :page => @page,
                                                   :per_page => @count)

        render "index.atom.builder"
      end
    end
  end

  # レコードの詳細情報の表示．
  def show
    @community_reply = CommunityReply.find(params[:id])
  end

  # 登録フォームの表示．
  def new
    @community_reply ||= @thread.replies.new(:author => current_user, :parent_id => params[:parent_id])
    @community_reply.build_attachments
    render "form"
  end

  # 編集フォームの表示．
  def edit
    @community_reply ||= CommunityReply.find(params[:id])
    @community_reply.build_attachments
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @community_reply = CommunityReply.new(params[:community_reply].merge(:community_id => @thread.community_id, :user_id => current_user.id))
    thread_type = @community_reply.thread.kind.underscore
    path = "new_#{thread_type}_reply_path"
    args = {"#{thread_type}_id" => @community_reply.thread.id, :member => params[:event_member]}

    return redirect_to send(path, args) if params[:clear]

    if @community_reply.valid?
      set_unpublic_image_uploader_keys(@community_reply)
      render "confirm"
    else
      new
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @community_reply = CommunityReply.find(params[:id])
    @community_reply.attributes = params[:community_reply]
    thread_type = @community_reply.thread.kind.underscore
    path = "edit_#{thread_type}_reply_path"
    args = {"#{thread_type}_id" => @community_reply.thread.id,
      :id => @community_reply }

    return redirect_to send(path, args) if params[:clear]

    if @community_reply.valid?
      set_unpublic_image_uploader_keys(@community_reply)
      render "confirm"
    else
      edit
    end
  end

  # 登録データをDBに保存．
  def create
    respond_to do |format|
      format.html do
        @community_reply = CommunityReply.new(params[:community_reply].merge(:community_id => @thread.community_id, :user_id => current_user.id))
        return new if params[:cancel] || !@community_reply.valid?

        CommunityReply.transaction do
          @community_reply.save!
          unless params[:event_member].blank?
            @community_reply.create_or_delete_event_member
          end
        end
        thread_type = @community_reply.thread.kind.underscore

        redirect_to send("complete_after_create_#{thread_type}_reply_path",
                         :id => @community_reply.id,
                         "#{thread_type}_id" => @community_reply.thread.id,
                         :community_id => @community_reply.thread.community.id,
                         :thread_id => @community_reply.thread.id,
                         :event_member => params[:event_member],
                         :path => "#{thread_type}_path")

      end
      format.atom do
        doc = REXML::Document.new body = request.raw_post
        title = REXML::XPath.first(doc, '/entry/title').text
        content = REXML::XPath.first(doc, '/entry/content').text
        if params[:topic_id]
          # トピックへのコメントの投稿
          topic = CommunityTopic.find(params[:topic_id])
        elsif params[:parent_id]
          # トピックのコメントへの返信
          parent = CommunityReply.find(params[:parent_id])
          topic = parent.thread
        end
        @reply = topic.replies.new(:user_id => current_user.id,
                                   :title => title,
                                   :content => content,
                                   :community_id => topic.community_id)
        @reply.parent_id = parent.id if parent
        if @reply.save
          # コメント取得時は、ReplyなのかTopicなのかを判定するために、
          # find時にobject_typeという別名のカラムをつけており、それに対応するために
          # ここでも同じようなことを行う。
          def @reply.object_type; "Reply"; end
          response.headers["Location"] =
            "http://#{request.host_with_port}/community_comments/#{@reply.id}.atom"
          render "create.atom.builder", :status => 201
        end
      end
    end
  end

  # 返信作成完了画面
  # NOTE: 作成時は、通常の完了画面とは異なり、上部に返信元の内容と、下部に返信がツリー形式で表示されるため、アクションを定義する
  def complete_after_create
    @community_reply = CommunityReply.find(params[:id])
    unless params[:event_member].blank?
      if params[:event_member] == "cancel"
        @message  = "このイベントへの参加をキャンセルしました。"
      elsif params[:event_member] == "entry"
        @message  = "このイベントへの参加が完了いたしました。"
      end
    end
    @message ||= "作成完了いたしました。"
  end

  # 更新データをDBに保存．
  def update
    @community_reply = CommunityReply.find(params[:id])
    @community_reply.attributes = params[:community_reply]
    return edit if params[:cancel] || !@community_reply.valid?

    CommunityReply.transaction do
      @community_reply.save!
    end

    thread_type = @community_reply.thread.kind.underscore

    redirect_to send("complete_after_update_#{thread_type}_reply_path",
                     :id => @community_reply.id,
                     "#{thread_type}_id" => @community_reply.thread.id,
                     :community_id => @community_reply.thread.community.id,
                     :thread_id => @community_reply.thread.id,
                     :path => "#{thread_type}_path")
  end

  # レコードの削除確認（携帯用）
  def confirm_before_destroy
    return redirect_to communities_url unless request.mobile?
  end

  # レコードの削除
  def destroy
    @community_reply = CommunityReply.find(params[:id])
    thread_type = @community_reply.thread.kind
    thread = @community_reply.thread
    # ここは論理削除
    @community_reply.set_deleted_flag

    redirect_to send(thread_type.underscore + "_path", :id => thread.id, :community_id => thread.community_id)
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    logged_in? ? communities_path : search_communities_path
  end

  # 返信文作成時に返信元から文章を引用し、フォームの内容を変更する
  def quote_content
    @community_reply = CommunityReply.new
    @community_reply.attributes = (params[:community_reply])
    @community_reply.content = @community_reply.quote_content
    render :partial => "community_reply_content_form"
  end

  private
  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : CommunityReply.default_index_order),
    }
  end

  def load_thread_and_set_community
    if params[:community_event_id] && CommunityEvent.exists?(params[:community_event_id])
      @thread = CommunityEvent.find(params[:community_event_id])
    elsif params[:community_topic_id] && CommunityTopic.exists?(params[:community_topic_id])
      @thread = CommunityTopic.find(params[:community_topic_id])
    elsif params[:community_marker_id] && CommunityMarker.exists?(params[:community_marker_id])
      @thread = CommunityMarker.find(params[:community_marker_id])
    end
    if @thread
      @community = @thread.community
    end
    return if @community

    if params[:topic_id]
      @community = CommunityTopic.find(params[:topic_id]).community
    elsif params[:parent_id]
      @community = CommunityReply.find(params[:parent_id]).community
    end
  end

  # 返信を編集する権限があるかどうか検証し、無ければトップページへ飛ばす
  def verify_reply_editable_or_destroyable
    reply = CommunityReply.find(params[:id])
    redirect_to root_path unless reply.editable?(current_user)
  end

  # 返信を作成する権限があるかどうか検証し、無ければトップページへ飛ばす
  def verify_reply_createable
    redirect_to root_path unless (@community.general?(current_user) || @community.sub_admin?(current_user) || @community.admin?(current_user))
  end

  # ファイルアップロードキー設定
  def set_unpublic_image_uploader_keys(reply)
    reply.attachments.each do |at|
      self.unpublic_image_uploader_key = at.image_temp unless at.image_temp.blank?
    end
  end

  # replyが論理削除されたか？
  def deleted_reply?
    CommunityReply.find(params[:id]).deleted?
  end
end

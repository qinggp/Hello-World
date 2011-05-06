# コミュニティ管理
class Admin::CommunitiesController < Admin::ApplicationController
  include Mars::UnpublicImageAccessible

  unpublic_image_accessible :model_name => :community

  with_options :redirect_to => :admin_communities_url do |con|
    con.verify :params => "id", :only => %w(destroy confirm_before_update)
    con.verify :params => "community",
      :only => %w(confirm_before_update update)
    con.verify :params => "type",
      :only => %w(wrote_administration_communities
                  wrote_administration_topics
                  wrote_administration_events)
    con.verify :method => :post, :only => %w(confirm_before_update)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete,
      :only => %w(destroy community_thread_file_destroy
                  community_reply_file_destroy communityt_file_destroy community_event_file_destroy)
  end

  # コミュニティ書き込み管理
  def wrote_administration_communities
    @search_id = params[:search_id] if params[:search_id] && params[:search_id] != ''
    if (params[:per_page] && params[:per_page].to_i == 0) || params[:search_id]
      @paginated = false
    else
      @paginated = true
    end
    case params[:type]
    when "write"
      conditions = ['not(visibility = 4 and approval_required = true)']
      if @paginated
        if params[:secret_view]
          conditions = ['visibility = 4 and approval_required = true']
          @secret_view = params[:secret_view]
        end
        @communities = Community.paginate(:conditions => conditions,
                                          :per_page => (params[:per_page] ? params[:per_page] : 5),
                                          :page => params[:page],
                                          :order => 'id desc')
      else
        if @search_id
          conditions[0] += ' and id = ?'
          conditions.push(@search_id.to_i)
        end
        @communities = Community.find(:all, :conditions => conditions, :order => 'id desc')
      end
      render "wrote_administration_communities_write"
    when "file"
      conditions = ["image <> '' "]
      if @paginated
        @communities = Community.paginate(:conditions => conditions,
                                          :per_page => (params[:per_page] ? params[:per_page] : 10),
                                          :page => params[:page],
                                          :order => 'created_at desc')
      else
        if @search_id
          conditions[0] += ' and id = ?'
          conditions.push(@search_id.to_i)
        end
        @communities = Community.find(:all, :conditions => conditions, :order => 'created_at desc')
      end
      render "wrote_administration_communities_file"
    end
  end

  # コミュニティトピック書き込み管理
  def wrote_administration_topics
    @search_id = params[:search_id] if params[:search_id] && params[:search_id] != ''
    if params[:community_id]
      sql = CommunityTopic.all_community_topics_query(params[:community_id])
    end

    case params[:type]
    when "write"
      if (params[:per_page] && params[:per_page].to_i == 0) || @search_id
        @paginated = false
        unless sql
          sql = @search_id ? CommunityTopic.topics_write_query(@search_id) : CommunityTopic.topics_write_query
        end
      else
        @paginated = true
        unless sql
          sql = CommunityTopic.topics_write_query
        end
      end
      if @paginated
        @community_topics = CommunityTopic.paginate_by_sql(sql,
                              {:per_page => params[:per_page] ? params[:per_page] : 5,
                               :page => params[:page] ? params[:page] : 1})
      else
        @community_topics = CommunityTopic.find_by_sql(sql)
      end
      render "wrote_administration_topics_write"
    when "file"
      if (params[:per_page] && params[:per_page].to_i == 0) || @search_id
        @paginated = false
        sql = @search_id ? CommunityThreadAttachment.topics_file_query(@search_id) : CommunityThreadAttachment.topics_file_query
      else
        sql = CommunityThreadAttachment.topics_file_query
        @paginated = true
      end
      if @paginated
        @attachments =
          CommunityThreadAttachment.paginate_by_sql(sql,
                              {:per_page => params[:per_page] ? params[:per_page] : 10,
                               :page => params[:page] ? params[:page] : 1})
      else
        @attachments = CommunityThreadAttachment.find_by_sql(sql)
      end
      render "wrote_administration_topics_file"
    end
  end

  # コミュニティイベント書き込み管理
  def wrote_administration_events
    @search_id = params[:search_id] if params[:search_id] && params[:search_id] != ''
    if params[:per_page] && params[:per_page].to_i == 0
      @paginated = false
    else
      @paginated = true
    end
    case params[:type]
    when "write"
      if @paginated
        conditions = []
        if @search_id
          conditions.push('id = ?')
          conditions.push(@search_id.to_i)
        end
        @community_events = CommunityEvent.paginate(
                              :conditions => conditions,
                              :per_page => (params[:per_page] ? params[:per_page] : 5),
                              :page => params[:page],
                              :order => 'created_at desc')
      else
        @community_events = CommunityEvent.all
      end
      render "wrote_administration_events_write"
    when "file"
      conditions = [<<-SQL
        community_threads.type = 'CommunityEvent'
      SQL
      ]
      if @search_id
        conditions.push(' and community_thread_file_destroy.thread_id = ?')
        conditions.push(@search_id.to_i)
      end
      if @paginated
        @community_thread_attachments = CommunityThreadAttachment.paginate(
                              :include => :thread,
                              :conditions => conditions,
                              :per_page => (params[:per_page] ? params[:per_page] : 10),
                              :page => params[:page],
                              :order => 'community_thread_attachments.created_at desc')
      else
        @community_thread_attachments =
          CommunityThreadAttachment.find(:all, :conditions => conditions)
      end
      render "wrote_administration_events_file"
    end
  end

  # 編集フォームの表示．
  def edit
    @community = Community.find(params[:id])
    if params[:community]
      params[:community].delete(:image_temp)
      @community.attributes = params[:community]
    end
    @community_admin = @community.admin
    render "form"
  end

  # 編集確認画面表示
  def confirm_before_update
    @community = Community.find(params[:id])
    @community.attributes = params[:community]
    @community_admin = @community.admin
    return redirect_to edit_admin_community_path(@community) if params[:clear]

    if @community.valid?
      set_unpublic_image_uploader_keys(@community)
      render "confirm"
    else
      render "form"
    end
  end

  # 更新データをDBに保存．
  def update
    @community = Community.find(params[:id])
    @community.attributes = params[:community]
    @community_admin = @community.admin
    return render "form" if params[:cancel] || !@community.valid?

    Community.transaction do
      @community.save!
      @community.add_members_to_official if !params[:initialization_official].blank? && @community.official?
    end

    redirect_to complete_after_update_admin_community_path(@community)
  end

# コミュニティ削除確認画面
  def confirm_before_destroy
    @community = Community.find(params[:id])

    return redirect_to edit_admin_community_path(@community.id) if params.has_key?(:cancel)
  end

  # コミュニティ削除
  def destroy
    if params[:id] && Community.exists?(params[:id])
      if params.has_key?(:cancel)
        redirect_to edit_admin_community_path(params[:id])
        return
      end

      if Community.destroy(params[:id])
        redirect_to complete_after_destroy_new_admin_community_path
      else
        flash[:error] = "削除失敗しました。"
        redirect_to community_path(params[:id])
      end
    end
  end

  # コミュニティ添付削除
  def community_file_destroy
    @community = Community.find(params[:id])
    @community.attributes = {:image => nil}

    Community.transaction do
      @community.save!
    end
    redirect_to wrote_administration_communities_admin_communities_path(:type => 'file')
  end

  # コミュニティイベント添付削除
  def community_event_file_destroy
    community_thread_attachment_destroy(params[:id])
    redirect_to wrote_administration_events_admin_communities_path(:type => 'file')
  end

  # コミュニティトピック添付削除
  def community_thread_file_destroy
    community_thread_attachment_destroy(params[:id])
    redirect_to wrote_administration_topics_admin_communities_path(:type => 'file')
  end

  # コミュニティトピック返信の添付削除
  def community_reply_file_destroy
    community_thread_reply_attachment = CommunityReplyAttachment.find(params[:id])
    unless community_thread_reply_attachment.destroy
      flash[:error] = "削除失敗しました。"
    end
    redirect_to wrote_administration_topics_admin_communities_path(:type => 'file')
  end

private

  def community_thread_attachment_destroy(id)
    community_thread_attachment = CommunityThreadAttachment.find(id)
    unless community_thread_attachment.destroy
      flash[:error] = "削除失敗しました。"
    end
  end

  # ファイルアップロードキー設定
  def set_unpublic_image_uploader_keys(community)
    self.unpublic_image_uploader_key = community.image_temp unless community.image_temp.blank?
  end


end


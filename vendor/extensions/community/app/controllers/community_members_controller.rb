class CommunityMembersController < ApplicationController
  include Mars::Community::CommonController

  before_filter :mobile_only,
                :only => [:show, :confirm_before_assing_sub_admin_with,
                          :confirm_before_assign_sub_admin_with,
                          :confirm_before_delegate_admin_to,
                          :confirm_before_remove_from_sub_admin,
                          :confirm_before_dismiss]

  before_filter :load_community
  before_filter :load_member,  :except => :index

  access_control do
    allow :community_admin, :of => :community
    allow :community_sub_admin, :of => :community,
          :to => [:index, :dismiss, :confirm_before_dismiss, :show]
  end

  layout "communities"

  # コミュニティ管理トップページ
  def index
    @members = @community.members.paginate(paginate_options_for_member)
  end

  # 副管理人を解任させる
  def remove_from_sub_admin
    ActiveRecord::Base.transaction do
      @member.has_no_roles_for!(@community)
      @member.has_role!("community_general", @community)
    end
    if request.mobile?
      redirect_to show_members_community_path(@community)
    else
      redirect_to community_members_path(:community_id => @community.id)
    end
  end

  # 副管理人に任命する
  def assign_sub_admin_with
    ActiveRecord::Base.transaction do
      @member.has_no_roles_for!(@community)
      @member.has_role!("community_sub_admin", @community)
    end
    if request.mobile?
      redirect_to show_members_community_path(@community)
    else
      redirect_to community_members_path(:community_id => @community.id)
    end
  end

  # 管理人権限を委譲する
  def delegate_admin_to
    ActiveRecord::Base.transaction do
      @community.delegate_admin_to(@member)
    end
    redirect_to community_path(@community.id)
  end

  # 強制退会させる
  def dismiss
    if @member.has_role?("community_admin", @community)
      flash[:error] = "管理人を退会させることはできません。"
      redirect_to community_members_path(:community_id => @community.id)
      return
    end
    ActiveRecord::Base.transaction do
      @community.remove_member!(@member)
    end
    if request.mobile?
      redirect_to show_members_community_path(@community)
    else
      redirect_to community_members_path(:community_id => @community.id)
    end
  end

  # 副管理人任命確認ページ
  # 携帯用
  def confirm_before_assign_sub_admin_with
    @title = "副管理人任命"

    render "confirm_before_assign_sub_admin_with"
  end

  # 副管理人解任確認ページ
  # 携帯用
  def confirm_before_remove_from_sub_admin
    @title = "副管理人解任"

    render "confirm_before_remove_from_sub_admin"
  end

  # 強制退会確認ページ
  # 携帯用
  def confirm_before_dismiss
    @title = "強制退会"

    render "confirm_before_dismiss"
  end

  # 管理権限委譲確認ページ
  # 携帯用
  def confirm_before_delegate_admin_to
    @title = "管理権限委譲"

    render "confirm_before_delegate_admin_to"
  end


  # メンバー表示
  # 携帯用で、ここから権限を操作する
  def show
    render "show"
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    logged_in? ? communities_path : search_communities_path
  end

  private

  def load_community
    if params[:community_id] && Community.exists?(params[:community_id])
      @community = Community.find(params[:community_id])
    end
  end

  def load_member
    if @community && params[:id] && @community.members.exists?(params[:id])
      @member = @community.users.find(params[:id])
    end
  end
end

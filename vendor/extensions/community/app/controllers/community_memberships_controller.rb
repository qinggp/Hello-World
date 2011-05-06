# ログインユーザが所属しているコミュニティの設定変更を扱うコントローラ
class CommunityMembershipsController < ApplicationController
  access_control do
    allow logged_in
  end

  layout "communities"

  # 所属しているコミュニティ一覧ページ
  def index
    @communities = current_user.communities.paginate(paginate_options)
  end

  # 最新書き込みの表示設定を変更する
  def change_new_comment_displayed
    community = Community.find(params[:id])
    unless community.change_new_comment_displayed(current_user)
      flash[:error] = "最新書き込みの表示設定変更に失敗しました"
    end
    redirect_to community_memberships_path
  end

  # 書き込み通知メール送信設定を変更する
  def change_comment_notice_acceptable
    community = Community.find(params[:id])
    unless community.change_comment_notice_acceptable(current_user)
      flash[:error] = "書き込み通知メールの送信設定変更に失敗しました"
    end
    redirect_to community_memberships_path
  end

  # 書き込み通知メール送信設定を変更する
  def change_comment_notice_acceptable_for_mobile
    community = Community.find(params[:id])
    unless community.change_comment_notice_acceptable_for_mobile(current_user)
      flash[:error] = "書き込み通知メールの送信設定変更に失敗しました"
    end
    redirect_to community_memberships_path
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    logged_in? ? communities_path : search_communities_path
  end

  private
  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : Community.default_index_order),
      :per_page => (per_page_for_all(Community) ? per_page_for_all(Communityr) : 30),
    }
  end
end

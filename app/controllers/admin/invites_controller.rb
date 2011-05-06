# 招待ユーザ管理
class Admin::InvitesController < Admin::ApplicationController

  # 一覧の表示と並び替え，レコードの検索．
  def index
    @invite = Invite.new(params[:invite])
    if @invite.email.blank?
      @invites = Invite.paginate(:all, paginate_options)
    else
      @invites =
        Invite.email_is(@invite.email).paginate(paginate_options)
    end
  end

  private
  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : Invite.default_index_order),
      :per_page => (params[:per_page] ? per_page_for_all(Invite) : 20),
    }
  end
end

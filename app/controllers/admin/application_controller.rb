class Admin::ApplicationController < ApplicationController
  layout "admin"

  before_filter :admin_user_check

  # レコード作成完了画面表示
  def complete_after_create
    @message = "作成完了いたしました。"
    render "/share/complete", :layout => "admin"
  end

  # レコード更新完了画面表示
  def complete_after_update
    @message = "修正完了いたしました。"
    render "/share/complete", :layout => "admin"
  end

  # レコード削除完了画面表示
  def complete_after_destroy
    @message = "削除完了いたしました。"
    render "/share/complete", :layout => "admin"
  end

  private
  def admin_user_check
    if !current_user.try(:admin?)
      return redirect_to root_url
    end
  end
end

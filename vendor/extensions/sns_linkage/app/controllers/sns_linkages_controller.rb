# SNS連携管理
class SnsLinkagesController < ApplicationController

  access_control do
    allow logged_in
  end

  # 新着情報
  def news
    @sns_linkages = SnsLinkage.by_enableds(current_user.id)
    render "index"
  end

  # お知らせ情報
  alias :info :news

  # SNS連携サイト設定画面表示
  def new
    @sns_linkages = SnsLinkage.user_id_is(current_user.id).descend_by_created_at
  end

  # SNS連携キー追加
  def create
    @sns_linkage = SnsLinkage.new(params[:sns_linkage])
    @sns_linkage.user = current_user
    unless @sns_linkage.valid?
      logger.debug{ "DEBUG :  #{@sns_linkage.to_yaml}" }
      return redirect_to new_sns_linkage_path
    end

    SnsLinkage.transaction do
      @sns_linkage.save!
    end
    redirect_to new_sns_linkage_path
  end

  # SNS連携キー削除
  def destroy
    @sns_linkage = SnsLinkage.user_id_is(current_user.id).find_by_id(params[:id])
    @sns_linkage.destroy if @sns_linkage
    redirect_to new_sns_linkage_path
  end

  # SNS連携キー発行
  def publish_link_key
    if params.has_key?(:unpublish)
      return redirect_to unpublish_link_key_sns_linkages_path
    end
    User.transaction do
      SnsLinkage.set_link_key!(current_user)
      current_user.save(false)
    end
    redirect_to new_sns_linkage_path
  end

  # SNS連携キー停止
  def unpublish_link_key
    User.transaction do
      current_user.sns_link_key = nil
      current_user.save(false)
    end
    redirect_to new_sns_linkage_path
  end

  # ヘルプ
  def help
    render "help", :layout => false
  end
end

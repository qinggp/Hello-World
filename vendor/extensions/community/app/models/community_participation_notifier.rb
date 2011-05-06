# コミュニティの設定で、メール通知を受けるときのみ動作する
# コミュニティへの参加があったときと、コミュニティへの参加依頼があったときに通知する
class CommunityParticipationNotifier < Mars::Iso2022jpMailer
  include Mars::MailSendable

  # memberへcommunity_userが参加依頼を行ったことを通知するメール
  def application(community_user, member)
    @user = member
    setup_subject!("#{community_user.user.name}さんがコミュニティに参加希望しています")
    @body["community_name"] = community_user.community.name
    @body["user_name"] = community_user.user.name
    @body["community_link"] = community_url(community_user.community.id, :host => CONFIG["host"])
    @body["user_link"] = user_url(community_user.user.id, :host => CONFIG["host"])
    @body["message"] = community_user.apply_message

    setup_send_info!(:user => member)
  end

  # 参加通知メール
  def notification(community, user, admin_member)
    @user = admin_member

    setup_subject!("#{user.name}さんがコミュニティに参加しました")
    @body["community_name"] = community.name
    @body["user_name"] = user.name
    @body["community_link"] = community_url(community.id, :host => CONFIG["host"])
    @body["user_link"] = user_url(user.id, :host => CONFIG["host"])
    setup_send_info!(:user => admin_member)
  end
end

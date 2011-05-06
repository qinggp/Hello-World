class CommunityApprovalNotifier < Mars::Iso2022jpMailer
  include Mars::MailSendable

  # 参加拒否お知らせメール
  def rejection(reject_community_user)
    setup_subject!("コミュニティへ参加が承認されませんでした")
    @body["community_name"] = reject_community_user.community.name
    @body["message"] = reject_community_user.reject_message
    @body["user_name"] = reject_community_user.user.name

    setup_send_info!(:user => reject_community_user.user)
  end

  # 参加承認お知らせメール
  def acceptance(accept_community_user)
    setup_subject!("コミュニティへ参加が承認されました")
    @body["community_name"] = accept_community_user.community.name
    @body["link"] = community_url(accept_community_user.community.id, :host => CONFIG["host"])
    @body["user_name"] = accept_community_user.user.name

    setup_send_info!(:user => accept_community_user.user)
  end
end

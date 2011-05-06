class UserApprovalNotifier < Mars::Iso2022jpMailer
  include Mars::MailSendable

  @@admin_name = "サイト管理者"
  
  # 承認待ちユーザへの参加承認お知らせ
  def approve_notification(user)
    setup_subject!("#{@@admin_name}さんがあなたの参加を承認しました")
    @body = {:user => user, :approval_user_name => @@admin_name}
    setup_send_info!(:user => user)
  end

  # 承認者へのユーザ承認のお知らせ
  def approve_notification_to_approver(approver, invite_user)
    setup_subject!("#{invite_user.name_and_full_real_name}さんが#{SnsConfig.title}に参加されました")
    @body = {:user => approver, :invite_user => invite_user}
    setup_send_info!(:user => approver)
  end

  # プロフィール変更依頼
  def rewrite_request(user)
    setup_subject!("#{@@admin_name}さんからメッセージが届いています")
    @body = {:user => user, :approval_user_name => @@admin_name}
    setup_send_info!(:user => user)
  end

  # 参加拒否
  def reject(user)
    setup_subject!("あなたの参加は承認されませんでした")
    @body = {:user => user, :approval_user_name => @@admin_name}
    setup_send_info!(:user => user)
  end
end

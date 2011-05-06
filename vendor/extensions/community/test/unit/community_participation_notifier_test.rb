require File.dirname(__FILE__) + '/../test_helper'

class CommunityParticipationNotifierTest < ActionMailer::TestCase
  tests CommunityParticipationNotifier

  def setup
    setup_emails
  end

  # 参加承認依頼メールの送信テスト
  def test_application
    admin_member = User.make
    sub_admin_member = User.make

    community = set_community_and_has_role(admin_member, :participation_and_visibility =>
                                           Community::APPROVALS_AND_VISIBILITIES[:approval_required_and_public],
                                           :participation_notice => true)
    community.members << sub_admin_member
    sub_admin_member.has_role!("community_sub_admin", community)

    user = User.make
    application_message = "おねがいします"
    community.receive_application(user, application_message)

    # 管理人と副管理人全員に届く
    assert_equal 2, @emails.size
    assert_equal [admin_member.login],  @emails.first.to
    assert_equal [admin_member.login],  @emails.first.reply_to
    assert_equal [sub_admin_member.login],  @emails.second.to
    assert_equal [sub_admin_member.login], @emails.second.reply_to

    mail = @emails.first
    assert_equal [SnsConfig.admin_mail_address], mail.from
    assert_match /コミュニティに参加希望しています/, NKF.nkf("-mJw", mail.subject)
    assert @emails.any?{ |m| m.body =~ /#{Regexp.escape admin_member.name}さん/ }
    assert_match /以下のURLをクリックして参加承認作業をしてください/, mail.body
    assert_match /#{application_message}/, mail.body

    # メッセージも管理人、副管理人宛に作成される
    assert_equal 2, Message.sender_id_is(user.id).size
    messages = Message.sender_id_is(user.id).all
    assert_match /コミュニティに参加希望しています/,  messages.first.subject
    assert messages.any?{ |m| m.body =~ /#{Regexp.escape admin_member.name}さん/ }
    assert_match /以下のURLをクリックして参加承認作業をしてください/, messages.first.body
    assert_match /#{application_message}/, messages.first.body
  end

  # 承認がない場合の参加通知メールの送信テスト
  def test_notification
    admin_member = User.make
    sub_admin_member = User.make

    community = set_community_and_has_role(admin_member, :participation_notice => true)
    community.members << sub_admin_member
    sub_admin_member.has_role!("community_sub_admin", community)

    user = User.make
    community.receive_application(user)

    # 管理人と副管理人全員に届く
    assert_equal 2, @emails.size
    assert_equal [admin_member.login],  @emails.first.to
    assert_equal [admin_member.login],  @emails.first.reply_to
    assert_equal [sub_admin_member.login],  @emails.second.to
    assert_equal [sub_admin_member.login], @emails.second.reply_to

    mail = @emails.first
    assert_equal [SnsConfig.admin_mail_address], mail.from
    assert_match /コミュニティに参加しました/, NKF.nkf("-mJw", mail.subject)
    assert_match /参加しましたのでご連絡致します。/, mail.body

    # メッセージも管理人、副管理人宛に作成される
    assert_equal 2, Message.sender_id_is(user.id).size
    message = Message.sender_id_is(user.id).first
    assert_match /コミュニティに参加しました/,  message.subject
    assert_match  /参加しましたのでご連絡致します。/, message.body
  end
end

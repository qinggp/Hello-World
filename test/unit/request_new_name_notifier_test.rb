require File.dirname(__FILE__) + '/../test_helper'

# 名前変更依頼通知テスト
class RequestNewNameNotifierTest < ActionMailer::TestCase
  tests RequestNewNameNotifier

  def setup
    setup_emails
  end

  # 名前変更依頼メール
  def test_notification
    user = User.make(:change_first_real_name => "変更名前",
                     :change_last_real_name => "変更名字",
                     :change_name_reason => "変更\nします。")
    request = Object.new
    stub(request).remote_host{ "remote host" }
    stub(request).remote_addr{ "remote addr" }
    stub(request).user_agent{ "user agent" }

    RequestNewNameNotifier.deliver_notification(user,request)
    assert !@emails.empty?

    sent = @emails.first

    assert_equal [SnsConfig.admin_mail_address], sent.to
    assert_equal [SnsConfig.admin_mail_address], sent.from

    assert_match /#{user.id}/, sent.body
    assert_match /#{user.name}/, sent.body
    assert_match /#{user.login}/, sent.body
    assert_match /#{user.last_real_name}/, sent.body
    assert_match /#{user.first_real_name}/, sent.body
    assert_match /#{user.change_first_real_name}/, sent.body
    assert_match /#{user.change_last_real_name}/, sent.body
    assert_match /#{user.change_name_reason}/, sent.body
    assert_match /remote host/, sent.body
    assert_match /remote addr/, sent.body
    assert_match /user agent/, sent.body
  end
end

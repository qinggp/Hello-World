require File.dirname(__FILE__) + '/../test_helper'

class TrackCountNotifilerTest < ActionMailer::TestCase
  tests TrackCountNotifiler

  def setup
    setup_emails
  end

  def test_notification
    user = User.make(:preference => Preference.make)

    visitor = User.make

    track_preference =
      user.preference.create_track_preference(:notification_track_count => 1)

    Track.make(:user_id => user.id, :visitor => visitor, :created_at => Time.now - 10000)

    assert_equal 1, @emails.size
    mail = @emails.first

    assert_equal [user.login], mail.to
    assert_equal [user.login], mail.reply_to
    assert_equal [SnsConfig.admin_mail_address], mail.from
    assert_match /あしあと#{track_preference.notification_track_count}件目はこの方です！/, NKF.nkf("-mJw", mail.subject)
    assert_match /記念すべき/, mail.body

    # 次のあしあとではメールが送信されない
    Track.make(:user_id => user.id, :visitor => visitor, :created_at => Time.now - 10000)
    assert_equal 1, @emails.size
  end
end

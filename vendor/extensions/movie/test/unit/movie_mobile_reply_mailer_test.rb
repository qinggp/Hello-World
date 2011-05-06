require File.dirname(__FILE__) + '/../test_helper'

# 動画メール登録結果通知テスト
class MovieMobileReplyMailerTest < ActionMailer::TestCase
  tests MovieMobileReplyMailer

  def setup
    setup_emails
  end

  # 動画登録正常完了通知
  def test_complete
    user = User.make
    movie = Movie.make

    MovieMobileReplyMailer.deliver_complete(user, movie)
    assert !@emails.empty?

    sent = @emails.first
    assert_equal [user.login], sent.to
    assert_equal [user.login], sent.reply_to
    assert_match /動画登録完了通知/, NKF.nkf("-mJw", sent.subject)
  end

  # 動画登録正常完了通知
  def test_unknown_mail
    address = "unkown@error.co.jp"
    movie = Movie.make

    MovieMobileReplyMailer.deliver_unknown_address(address)
    assert !@emails.empty?

    sent = @emails.first
    assert_equal [address], sent.to
    assert_equal [address], sent.reply_to
    assert_match /動画登録エラー通知/, NKF.nkf("-mJw", sent.subject)
  end

  # 動画登録正常完了通知
  def test_error
    user = User.make
    movie = Movie.make

    MovieMobileReplyMailer.deliver_error(user, "テスト", "war is over.\ngo home.")
    assert !@emails.empty?

    sent = @emails.first
    assert_equal [user.login], sent.to
    assert_equal [user.login], sent.reply_to
    assert_match /動画登録エラー通知/, NKF.nkf("-mJw", sent.subject)
    assert_match /テスト/, sent.body
    assert_match /war is over/, sent.body
  end
end

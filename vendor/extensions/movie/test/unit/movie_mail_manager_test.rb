require File.dirname(__FILE__) + '/../test_helper'

# 動画メール投稿テスト
class MovieMailManagerTest < ActionMailer::TestCase
  tests MovieMailManager

  def setup
    @real_mobile_email = "SnS_tarou@example.com"
    @user = User.make(:mobile_email => @real_mobile_email)
  end

  # 動画投稿
  def test_receive
    address = MovieMailManager.mars_receive_address(@user)
    mail =
      make_mail_text(:from => @real_mobile_email,
                     :sender => @real_mobile_email,
                     :to => address,
                     :subject => "subject_test",
                     :body => "body_test",
                     :file_paths => [File.join(File.dirname(__FILE__), "../fixtures/movie/video.3gp")],
                     :content_types => [["video", "3gp"]]
                     )

    assert_difference "Movie.count", 1 do
      MovieMailManager.receive(mail)
    end

    movie = Movie.find_by_title("subject_test")
    assert_equal "subject_test", movie.title
    assert_equal "body_test\r\n", movie.body
    assert_equal @user.preference.movie_preference.default_visibility, movie.visibility
    assert_equal Movie::CONVERT_STATUSES[:done], movie.convert_status
    assert_equal true, File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.3gp"))
    assert_equal true, File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.flv"))
    assert_equal true, File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.3g2"))
    movie.remove_movie_files
  end

  # 不明なアドレスからの受信
  def test_receive_unknown_mail_address
    mail =
      make_mail_text(:from => "unknown@mail.com",
                     :to => "unknown@mail.com",
                     :subject => "subject_test",
                     :body => "body_test"
                     )

    assert_difference "Movie.count", 0 do
      MovieMailManager.receive(mail)
    end
  end

  # 宛先が複数ある場合
  def test_receive_for_multiple_addresses
    addresses = %W(test1@example.com  #{MovieMailManager.mars_receive_address(@user)} test2@example.com)
    mail =
      make_mail_text(:from => @real_mobile_email,
                     :sender => @real_mobile_email,
                     :to => addresses,
                     :subject => "subject_test",
                     :body => "body_test",
                     :file_paths => [File.join(File.dirname(__FILE__), "../fixtures/movie/video.3gp")],
                     :content_types => [["video", "3gp"]]
                     )

    assert_difference "Movie.count", 1 do
      MovieMailManager.receive(mail)
    end

    movie = Movie.find_by_title("subject_test")
    assert_equal "subject_test", movie.title
    assert_equal "body_test\r\n", movie.body
    assert_equal @user.preference.movie_preference.default_visibility, movie.visibility
    assert_equal Movie::CONVERT_STATUSES[:done], movie.convert_status
    assert_equal true, File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.3gp"))
    assert_equal true, File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.flv"))
    assert_equal true, File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.3g2"))
    movie.remove_movie_files
  end
end

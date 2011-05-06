require File.dirname(__FILE__) + '/../test_helper'

# プロフィール顔写真アップロードテスト
class FacePhotoReceiverTest < ActionMailer::TestCase
  tests FacePhotoReceiver

  def setup
    @real_mobile_email = "SnS_tarou@example.com"
    @user = User.make(:mobile_email => @real_mobile_email)
  end

  # プロフィール顔写真投稿
  def test_receive_with_update
    @user.face_photo = before_face_photo = FacePhoto.make
    @user.save!
    address = FacePhotoReceiver.mars_receive_address(@user)

    mail =
      make_mail_text(:from => @real_mobile_email,
                     :sender => @real_mobile_email,
                     :to => address,
                     :subject => "subject_test",
                     :body => "body_test",
                     :file_paths => [File.join(File.dirname(__FILE__), "../fixtures/files/test_2.png")],
                     :content_types => [["image", "png"]]
                     )

    FacePhotoReceiver.receive(mail)

    @user = User.find(@user.id)
    assert_not_nil @user.face_photo
    assert_not_nil @user.face_photo.image
    assert_match "test_2.png", @user.face_photo.image
    assert_equal before_face_photo.id, @user.face_photo.id
  end

  # プロフィール顔写真投稿
  def test_receive_with_create
    address = FacePhotoReceiver.mars_receive_address(@user)

    mail =
      make_mail_text(:from => @real_mobile_email,
                     :sender => @real_mobile_email,
                     :to => address,
                     :subject => "subject_test",
                     :body => "body_test",
                     :file_paths => [File.join(File.dirname(__FILE__), "../fixtures/files/test.png")],
                     :content_types => [["image", "png"]]
                     )

    FacePhotoReceiver.receive(mail)

    @user = User.find(@user.id)
    assert_not_nil @user.face_photo
    assert_not_nil @user.face_photo.image
    assert_match "test.png", @user.face_photo.image
  end

  # 顔写真投稿で、複数アドレスがある場合
  def test_receive_for_multiple_addresses
    @user.face_photo = before_face_photo = FacePhoto.make
    @user.save!
    address = addresses = %W(test1@example.com  #{FacePhotoReceiver.mars_receive_address(@user)} test2@example.com)

    mail =
      make_mail_text(:from => @real_mobile_email,
                     :sender => @real_mobile_email,
                     :to => addresses,
                     :subject => "subject_test",
                     :body => "body_test",
                     :file_paths => [File.join(File.dirname(__FILE__), "../fixtures/files/test_2.png")],
                     :content_types => [["image", "png"]]
                     )

    FacePhotoReceiver.receive(mail)

    @user = User.find(@user.id)
    assert_not_nil @user.face_photo
    assert_not_nil @user.face_photo.image
    assert_match "test_2.png", @user.face_photo.image
    assert_equal before_face_photo.id, @user.face_photo.id
  end
end

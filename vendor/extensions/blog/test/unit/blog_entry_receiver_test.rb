require File.dirname(__FILE__) + '/../test_helper'

# ブログ記事メール投稿テスト
class BlogEntryReceiverTest < ActionMailer::TestCase
  tests BlogEntryReceiver

  def setup
    @real_mobile_email = "SnS_tarou@example.com"
    @user = User.make(:mobile_email => @real_mobile_email)
  end

  # ブログ記事投稿
  def test_receive
    address = BlogEntryReceiver.mars_receive_address(@user)
    @user.preference.blog_preference.update_attributes!(:visibility => BlogPreference::VISIBILITIES[:member_only],
                                                        :email_post_visibility => BlogPreference::VISIBILITIES[:member_only])


    mail = <<EOF
To: #{address}
From: =?ISO-2022-JP?B?GyRCQ2ZCPBsoQiAbJEJALk1OGyhC?= <#{@real_mobile_email}>
Sender: #{@real_mobile_email}
Subject: =?ISO-2022-JP?B?GyRCOm42SEpzOXAbKEI=?=
Content-Type: text/plain; charset="iso-2022-jp"

=?ISO-2022-JP?B?GyRCOm42SEpzOXAbKEI=?=
EOF

    assert_difference "BlogEntry.count", 1 do
      BlogEntryReceiver.receive(mail)
    end

    entry = BlogEntry.find(:all, :order => "created_at").last
    assert_equal "作業報告", entry.title
    assert_equal "作業報告\n", entry.body
    assert_not_nil entry.blog_category
    assert_equal @user.preference.blog_preference.email_post_visibility, entry.visibility
    assert_equal @user.preference.blog_preference.email_post_visibility, entry.comment_restraint
    assert @user.has_role?(:blog_entry_author, entry)
  end

  # ブログ記事投稿（添付ファイル付き）
  def test_receive_with_attachments
    address = BlogEntryReceiver.mars_receive_address(@user)
    mail =
      make_mail_text(:from => @real_mobile_email,
                     :sender => @real_mobile_email,
                     :to => address,
                     :subject => "subject_test",
                     :body => "body_test",
                     :file_paths => [File.join(File.dirname(__FILE__), "../fixtures/files/test.txt"),
                                     File.join(File.dirname(__FILE__), "../fixtures/files/test.gif"),
                                     File.join(File.dirname(__FILE__), "../fixtures/files/test.gif")],
                     :content_types => [["image", "txt"], ["image", "gif"], ["image", "gif"]]
                     )

    assert_difference "BlogEntry.count", 1 do
      assert_difference "BlogAttachment.count", 3 do
        BlogEntryReceiver.receive(mail)
      end
    end

    entry = BlogEntry.find(:all, :order => "created_at ASC").last
    assert_equal "subject_test", entry.title
    assert_equal "body_test\r\n", entry.body
    assert_equal @user.preference.blog_preference.email_post_visibility, entry.visibility
    assert_equal @user.preference.blog_preference.email_post_visibility, entry.comment_restraint
    attachments = entry.blog_attachments(:order => "position ASC")
    assert_not_nil attachments[0].image
    assert_equal "test.txt", File.basename(attachments[0].image)
    assert_equal "test.gif", File.basename(attachments[1].image)
    assert_equal "test.gif", File.basename(attachments[2].image)
    assert @user.has_role?(:blog_entry_author, entry)
  end

  # ブログ記事投稿
  # メール投稿時のコメント制限に関するテスト
  # メール投稿時のブログ自体の公開制限が外部公開のときは、コメント制限はメンバーのみになる
  def test_receive_for_comment_restraint_publiced
    address = BlogEntryReceiver.mars_receive_address(@user)
    @user.preference.blog_preference.update_attributes!(:visibility => BlogPreference::VISIBILITIES[:publiced],
                                                        :email_post_visibility => BlogPreference::VISIBILITIES[:publiced])

    mail = <<EOF
To: #{address}
From: =?ISO-2022-JP?B?GyRCQ2ZCPBsoQiAbJEJALk1OGyhC?= <#{@real_mobile_email}>
Sender: #{@real_mobile_email}
Subject: =?ISO-2022-JP?B?GyRCOm42SEpzOXAbKEI=?=
Content-Type: text/plain; charset="iso-2022-jp"

=?ISO-2022-JP?B?GyRCOm42SEpzOXAbKEI=?=
EOF

    assert_difference "BlogEntry.count", 1 do
      BlogEntryReceiver.receive(mail)
    end

    entry = BlogEntry.find(:all, :order => "created_at").last
    assert_equal "作業報告", entry.title
    assert_equal "作業報告\n", entry.body
    assert_not_nil entry.blog_category
    assert_equal @user.preference.blog_preference.email_post_visibility, entry.visibility
    assert_not_equal @user.preference.blog_preference.email_post_visibility, entry.comment_restraint
    assert entry.comment_restraint_member_only?
    assert @user.has_role?(:blog_entry_author, entry)
  end

  # ブログ記事投稿でToに複数ある場合
  def test_receive_for_multiple_addresses
    addresses = %W(test1@example.com  #{BlogEntryReceiver.mars_receive_address(@user)} test2@example.com)
    @user.preference.blog_preference.update_attributes!(:visibility => BlogPreference::VISIBILITIES[:member_only],
                                                        :email_post_visibility => BlogPreference::VISIBILITIES[:member_only])


    mail = <<EOF
To: #{addresses.join(",")}
From: =?ISO-2022-JP?B?GyRCQ2ZCPBsoQiAbJEJALk1OGyhC?= <#{@real_mobile_email}>
Sender: #{@real_mobile_email}
Subject: =?ISO-2022-JP?B?GyRCOm42SEpzOXAbKEI=?=
Content-Type: text/plain; charset="iso-2022-jp"

=?ISO-2022-JP?B?GyRCOm42SEpzOXAbKEI=?=
EOF

    assert_difference "BlogEntry.count", 1 do
      BlogEntryReceiver.receive(mail)
    end

    entry = BlogEntry.find(:all, :order => "created_at").last
    assert_equal "作業報告", entry.title
    assert_equal "作業報告\n", entry.body
    assert_not_nil entry.blog_category
    assert_equal @user.preference.blog_preference.email_post_visibility, entry.visibility
    assert_equal @user.preference.blog_preference.email_post_visibility, entry.comment_restraint
    assert @user.has_role?(:blog_entry_author, entry)
  end
end

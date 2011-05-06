require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :users

  def setup
    setup_emails
  end

  def test_should_create_user
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
      assert_not_nil user.private_token
    end
  end

  def test_should_require_login
    assert_no_difference 'User.count' do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference 'User.count' do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference 'User.count' do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_reset_password
    users(:quentin).update_attributes(:password => 'newpassword', :password_confirmation => 'newpassword')
    assert_equal users(:quentin), User.authenticate('quentin@example.com', 'newpassword')
  end

  def test_should_not_rehash_password
    users(:quentin).update_attributes(:login => 'quentin2@example.com')
    assert_equal users(:quentin), User.authenticate('quentin2@example.com', 'monkey')
  end

  def test_should_authenticate_user
    assert_equal users(:quentin), User.authenticate('quentin@example.com', 'monkey')
  end

  def test_should_set_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    users(:quentin).forget_me
    assert_nil users(:quentin).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    users(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    users(:quentin).remember_me_until time
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert_equal users(:quentin).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    users(:quentin).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end

  # 誕生日を判定するメソッドのテスト
  def test_birthday
    user = User.make(:birthday => Date.civil(2000, 1, 1))

    assert user.birthday?(Date.civil(2010, 1, 1))
    assert !user.birthday?(Date.civil(2010, 1, 2))

    # 閏年の2/29生まれの人の誕生日の判定をテスト
    user = User.make(:birthday => Date.civil(1984, 2, 29))

    assert !user.birthday?(Date.civil(2010, 2, 28))
    assert user.birthday?(Date.civil(2010, 3, 1))

    assert !user.birthday?(Date.civil(2012, 2, 28))
    assert user.birthday?(Date.civil(2012, 2, 29))
    assert !user.birthday?(Date.civil(2012, 3, 1))
  end

  # 年齢を計算するメソッドのテスト
  def test_age
    user = User.make(:birthday => Date.civil(2000, 1, 1))

    assert 10, Date.civil(2010, 12, 31)
    assert 11, Date.civil(2011, 1, 1)

    # 閏年の2/29生まれの人の年齢計算をテスト
    user = user = User.make(:birthday => Date.civil(1984, 2, 29))
    assert 22, Date.civil(2007, 2, 28)
    assert 23, Date.civil(2007, 3, 1)

    assert 23, Date.civil(2008, 2, 28)
    assert 24, Date.civil(2008, 2, 29)
    assert 24, Date.civil(2008, 3, 1)
  end

  # 顔写真子オブジェクト設定
  def test_face_photo_attributes
    user = User.new(:photo_attributes => {:face_photo_attributes => FacePhoto.plan})

    assert_not_nil user.face_photo
    assert_equal "FacePhoto", user.face_photo_type

    photo = FacePhoto.make
    user = User.make(:photo_attributes => {:face_photo => photo})
    user.photo_attributes = {:face_photo_attributes => FacePhoto.plan(:_delete => "1")}
    assert_not_nil user.face_photo._delete
  end

  # 顔写真子オブジェクト削除
  def test_face_photo_destroy
    photo = FacePhoto.make
    user = User.make(:face_photo => photo)

    user.photo_attributes = {:face_photo_attributes => {:_delete => "1"}}
    user.save!

    assert_not_nil user.face_photo
    assert_nil FacePhoto.find_by_id(photo.id)
  end

  # プロフィール閲覧制限
  def test_visible_profile
    you = User.make(:birthday_visibility => User::VISIBILITIES[:friend_only],
                      :job_visibility => User::VISIBILITIES[:unpubliced])
    other = User.make(:birthday_visibility => User::VISIBILITIES[:friend_only],
                      :job_visibility => User::VISIBILITIES[:unpubliced])

    you.friend!(other)

    assert_equal true, other.visible_profile?(you, "affiliation")
    assert_equal true, other.visible_profile?(you, "birthday")
    assert_equal false, other.visible_profile?(you, "job")
    assert_equal true, you.visible_profile?(you, "birthday")
    assert_equal false, you.visible_profile?(you, "job")

    you = User.make
    other = User.make(:affiliation_visibility => User::VISIBILITIES[:friend_only],
                      :birthday_visibility => User::VISIBILITIES[:member_only],
                      :job_visibility => User::VISIBILITIES[:unpubliced])


    assert_equal false, other.visible_profile?(you, "affiliation")
    assert_equal true, other.visible_profile?(you, "birthday")
    assert_equal false, other.visible_profile?(you, "job")
  end

  # メンバ検索
  def test_search_member_options
    u = User.make

    res = User.search_member_options(:name => u.name,
                                     :first_real_name => u.first_real_name,
                                     :last_real_name => u.last_real_name,
                                     :first_real_name => u.first_real_name,
                                     :gender => u.gender,
                                     :now_prefecture_id => u.now_prefecture_id,
                                     :now_city => u.now_city,
                                     :home_prefecture_id => u.home_prefecture_id,
                                     :search_hobby_id => "1",
                                     :message => u.message,
                                     :haved_face_photo => "1",
                                     :age_range_start => "2",
                                     :age_range_end => "3")

    assert_equal u.name, res[:name_like]
    assert_equal u.first_real_name, res[:first_real_name_is]
    assert_equal u.last_real_name, res[:last_real_name_is]
    assert res[:real_name_visibility_equals].include?(User::VISIBILITIES[:publiced])
    assert_equal u.gender, res[:gender_is]
    assert_equal u.now_prefecture_id, res[:now_prefecture_id_is]
    assert_equal u.now_city, res[:now_city_like]
    assert_equal u.home_prefecture_id, res[:home_prefecture_id_is]
    assert_equal "1", res[:by_hobby_id]
    assert_equal u.message, res[:message_like]
    assert_equal u.message, res[:detail_like]
    assert_equal true, res[:face_photo_id_not_null]
    assert_equal 2.years.ago.to_date, res[:birthday_lte]
    assert_equal 4.years.ago.to_date, res[:birthday_gt]
    assert res[:birthday_visibility_equals].include?(User::VISIBILITIES[:publiced])

    res = User.search_member_options(:age_range_start => 1)
    assert_equal 2.years.ago.to_date, res[:birthday_gt]

    res = User.search_member_options(:name => "", :first_real_name => "", :last_real_name => "",
                                     :first_real_name => "", :gender => "", :now_prefecture_id => "",
                                     :now_city => "", :home_prefecture_id => "", :search_hobby_id => "",
                                     :message => "", :haved_face_photo => "", :age_range_start => "",
                                     :age_range_end => "")
    assert_nil res[:name_like]
    assert_nil res[:first_real_name_is]
    assert_nil res[:last_real_name_is]
    assert_nil res[:real_name_visibility_equals]
    assert_nil res[:gender_is]
    assert_nil res[:now_prefecture_id_is]
    assert_nil res[:now_city_like]
    assert_nil res[:home_prefecture_id_is]
    assert_nil res[:by_hobby_id]
    assert_nil res[:message_like]
    assert_nil res[:detail_like]
    assert_nil res[:face_photo_id_not_null]
    assert_nil res[:birthday_lt]
    assert_nil res[:birthday_gt]
    assert_nil res[:birthday_visibility_equals]

    res = User.search_member_options(:first_real_name => u.first_real_name)
    assert_not_nil res[:last_real_name_is]
  end

  # ログイン時間保存
  def test_update_logged_in_at
    u = User.make
    u.update_logged_in_at!

    assert_not_nil u.logged_in_at
  end

  # 最終ログイン時間（現在の時刻からの差分）
  def test_logged_in_at_by_diff
    %w(2 4 9 14 44 59).each do |i|
      assert_equal("#{i.to_i+1}分以内",
                   User.make(:logged_in_at => i.to_i.minutes.ago).logged_in_at_by_diff)
    end
    assert_equal("2時間以内",
                 User.make(:logged_in_at => 1.hour.ago).logged_in_at_by_diff)
    assert_equal("2日以内",
                 User.make(:logged_in_at => 1.day.ago).logged_in_at_by_diff)
    assert_equal("1週間以上",
                 User.make(:logged_in_at => 6.day.ago).logged_in_at_by_diff)
  end

  # ユーザの承認
  def test_activate
    SnsConfig.master_record.
      update_attributes!(:approval_type =>
        SnsConfig::APPROVAL_TYPES[:approved_by_administrator])

    invite = Invite.make
    user = User.make(:login => invite.email,
                     :invitation_id => invite.user_id,
                     :approval_state => "pending")

    user.activate!
    assert_equal 'active', user.approval_state
    assert_equal true, invite.user.friend_user?(user)
    assert_equal true, user.friend_user?(invite.user)
    assert_nil Invite.find_by_id(invite.id)
  end

  # ユーザの承認（メール送信）
  def test_activate_with_notification
    SnsConfig.master_record.
      update_attributes!(:approval_type =>
        SnsConfig::APPROVAL_TYPES[:approved_by_administrator])

    user = User.make(:approval_state => "pending")

    user.activate_with_notification!(User.make)
    assert_equal 2, @emails.size
  end

  # トモダチ追加
  def test_friend!
    user = User.make
    friend = User.make
    Friendship.make(:user => user, :friend => friend, :approved => false)

    user.friend!(friend)
    assert_equal 1, user.friends.size
    assert_equal 1, user.friends_count
    assert_not_nil user.friendship_by_user_id(friend.id)
    assert_equal true, user.friendship_by_user_id(friend.id).approved
    assert_not_nil friend.friendship_by_user_id(user.id)
    assert_equal true, friend.friendship_by_user_id(user.id).approved

    user.friend!(friend)
    assert_equal 1, user.friendships.size
  end

  # トモダチから外す
  def test_break_off
    user = User.make
    friend = User.make

    user.friend!(friend)
    assert_equal 1, user.friends_count
    assert_equal true, user.friend_user?(friend)

    user.break_off!(friend)
    assert_equal 0, user.friends_count
    assert_equal false, user.friend_user?(friend)
  end

  # 対象ユーザとのサイト内の関係性
  def test_relationship_to_user
    user = User.make
    friend = User.make
    friend_friend = User.make
    user.friend!(friend)
    friend.friend!(friend_friend)

    assert_equal 2, user.relationship_to_user(friend).size
    assert_equal 3, user.relationship_to_user(friend_friend).size
    assert_equal 0, user.relationship_to_user(User.make).size
  end

  # ユーザ削除時に関連したレコードが削除されるか
  def test_user_destroy
    user = User.make
    friend = User.make(:invitation => user)
    user.friend!(friend)
    user.face_photo = face_photo = FacePhoto.make
    send_message = Message.make(:receiver => friend)
    user.sent_messages << send_message
    user.received_messages << Message.make(:sender => friend)
    user.has_role!(:test_user_destroy)
    user.hobbies << Hobby.make
    group = Group.make(:user_id => user.id)
    group.add_friend(friend)
    user.invites << Invite.make
    ForgotPassword.make(:user => user, :email => user.login)
    user.save!

    assert_not_nil FacePhoto.find(face_photo.id)
    assert_not_nil Message.find_by_receiver_id(user.id)
    assert_not_nil Message.find_by_sender_id(user.id)
    assert_not_nil Friendship.find_by_user_id(user.id)
    assert_not_nil Friendship.find_by_friend_id(friend.id)
    assert_not_nil Friendship.find_by_user_id(friend.id)
    assert_not_nil Friendship.find_by_friend_id(user.id)
    assert_not_nil role = Role.find_by_name("test_user_destroy")
    assert_not_nil RolesUser.find_by_user_id(user.id)
    assert_not_nil UsersHobby.find_by_user_id(user.id)
    assert_not_nil Group.find_by_user_id(user.id)
    assert_not_nil GroupMembership.find_by_user_id(friend.id)
    assert_not_nil Invite.find_by_user_id(user.id)
    assert_not_nil ForgotPassword.find_by_user_id(user.id)

    user.destroy

    assert_nil FacePhoto.find_by_id(face_photo.id)
    assert_nil Message.find_by_receiver_id(user.id)
    assert_nil Message.find_by_sender_id(user.id)
    assert_nil Friendship.find_by_user_id(user.id)
    assert_nil Friendship.find_by_friend_id(friend.id)
    assert_nil Friendship.find_by_user_id(friend.id)
    assert_nil Friendship.find_by_friend_id(user.id)
    assert_nil role = Role.find_by_name("test_user_destroy")
    assert_nil RolesUser.find_by_user_id(user.id)
    assert_nil UsersHobby.find_by_user_id(user.id)
    assert_nil Group.find_by_user_id(user.id)
    assert_nil GroupMembership.find_by_user_id(friend.id)
    assert_not_nil User.find(friend.id)
    assert_nil User.find(friend.id).invitation
    assert_nil Invite.find_by_user_id(user.id)
    assert_nil ForgotPassword.find_by_user_id(user.id)
  end

  # 本名が修正されているか？のチェック
  def test_valid_real_name_not_changed
    u = User.make
    assert_equal true, u.valid_real_name_not_changed?

    u.last_real_name = "update"
    assert_equal false, u.valid_real_name_not_changed?

    u = User.make
    u.first_real_name = "update"
    assert_equal false, u.valid_real_name_not_changed?
  end

  # ある月に誕生日があるユーザ一覧取得
  def test_by_birthday_on_month
    User.destroy_all
    birthday = 10.year.ago.beginning_of_month
    User.make(:birthday => birthday)
    assert_equal 1, User.by_birthday_on_month(Date.today.year, Date.today.month).size
  end

  # 閏年の2/29生まれの人が、平年は3月生まれ、閏年は2月生まれとして判定されるかテスト
  def test_by_birthday_on_month_for_leap
    User.destroy_all
    birthday = Date.new(1996, 2, 29)
    User.make(:birthday => birthday)

    # 平年は3月生まれ
    assert_equal 0, User.by_birthday_on_month(2010, 2).size
    assert_equal 1, User.by_birthday_on_month(2010, 3).size

    # 閏年は2月生まれ
    assert_equal 1, User.by_birthday_on_month(2012, 2).size
    assert_equal 0, User.by_birthday_on_month(2012, 3).size
  end

  # プロフィールページを表示してよいかどうかのテスト
  def test_profile_displayable
    user = User.make(:preference => Preference.make(:profile_restraint_type => Preference::PROFILE_RESTRAINT_TYPES[:member]))
    assert user.profile_displayable?(User.make)
    assert !user.profile_displayable?(nil)

    user = User.make(:preference => Preference.make(:profile_restraint_type => Preference::PROFILE_RESTRAINT_TYPES[:public]))
    assert user.profile_displayable?(User.make)
    assert user.profile_displayable?(nil)
  end

  protected
  def create_user(options = {})
    record = User.new(User.plan.merge({ :login => 'quire@example.com', :mobile_email => 'quire@example.com', :password => 'quire69', :password_confirmation => 'quire69'}).merge(options))
    record.save
    record
  end
end

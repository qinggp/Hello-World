require 'machinist/active_record'
require 'sham'
require 'faker'

Sham.define do
  login { "#{Faker.letterify("???")}#{Time.now.to_i}@example.com" }
  name { Faker::Name.name }
  mobile_email { Faker::Internet.email }
  email { Faker::Internet.email }
end

User.blueprint do
  login
  name
  mobile_email
  preference
  salt { "ac3478d69a3c81fa62e60f5c3696165a4e5e6ac4" } # SHA1('1')
  private_token { "ac3478d69a" } # SHA1('1')
  crypted_password { "b2392c36c27866f6e9437ffe1fab14bbba0b6ebe" } # 'monkey'
  remember_token_expires_at { 1.days.from_now.to_s }
  remember_token { "c1dfd96eea8cc2b62785275bca38ac261256e278" }
  openid_url { "http://#{Faker::Internet.domain_name}/" }
  birthday { Date.today }
  birthday_visibility { User::VISIBILITIES[:publiced] }
  first_real_name { "SNS" }
  last_real_name { "松江" }
  real_name_visibility { User::VISIBILITIES[:publiced] }
  now_prefecture_id { 1 }
  now_zipcode { "690-0826" }
  now_city { "松江市" }
  now_street { "学園南2丁目12-5" }
  now_address_visibility { User::VISIBILITIES[:publiced] }
  gender { User::GENDERS[:male] }
  blood_type { User::BLOOD_TYPES[:a] }
  home_prefecture_id { 1 }
  phone_number { Faker.numerify('###-####-####') }
  job_id { 1 }
  job_visibility { User::VISIBILITIES[:publiced] }
  affiliation { "NaCl" }
  affiliation_visibility { User::VISIBILITIES[:publiced] }
  message { "一言メッセージ" }
  detail { "自己紹介" }
  logged_in_at{ Time.now }
  approval_state{ 'active' }
end

Preference.blueprint do
  home_layout_type { Preference::HOME_LAYOUT_TYPES[:default] }
end

Message.blueprint do
  sender { User.make }
  receiver { User.make }
  subject { "タイトル" }
  body { "本文" }
  unread { true }
  deleted_by_sender { false }
  deleted_by_receiver { false }
  replied { false }
end

MessageAttachment.blueprint do
  image { ActionController::TestUploadedFile.new(RAILS_ROOT + "/test/fixtures/files/test.png", "image/png") }
  position { 1 }
end

ForgotPassword.blueprint do
  reset_code { Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join ) }
end

FacePhoto.blueprint do
  image { ActionController::TestUploadedFile.new(RAILS_ROOT + "/test/fixtures/files/test.png", "image/png") }
end

PreparedFacePhoto.blueprint do
  name { "テスト" }
  image { ActionController::TestUploadedFile.new(RAILS_ROOT + "/test/fixtures/files/test.png", "image/png") }
  position { PreparedFacePhoto.count + 2 }
end

JpAddress.blueprint do
  zipcode { 6900826 }
  prefecture_id { 32 }
  city { "松江市" }
  town { "学園南" }
end

Hobby.blueprint do
  name { "趣味" }
  position {Hobby.count+1}
end

Group.blueprint do
  name { "グループ名" }
end

GroupMembership.blueprint do
end

MessageAttachmentAssociation.blueprint do
end

Friendship.blueprint do
  user { User.make }
  friend { User.make }
  description { nil }
  relation { Friendship::RELATIONS[:nothing] }
  contact_frequency { Friendship::CONTACT_FREQUENCIES[:nothing] }
  approved{ true }
end

Information.blueprint do
  display_link{ Information::DISPLAY_LINKS[:link] }
  display_type{ Information::DISPLAY_TYPES[:new] }
  public_range{ Information::PUBLIC_RANGES[:sns_only] }
  title{ "テストのお知らせ" }
  expire_date{ 2.year.since }
end

SnsConfig.blueprint do
  title {"テストSNS名"}
  outline {"テスト概要"}
  admin_mail_address {Faker::Internet.email}
  entry_type { SnsConfig::ENTRY_TYPES[:invitation] }
  invite_type { SnsConfig::INVITE_TYPES[:invite]}
  approval_type { SnsConfig::APPROVAL_TYPES[:no_approval]}
  login_display_type { SnsConfig::LOGIN_DISPLAY_TYPES[:form_type] }
  if Mars::Extension.instance.extension_enabled?(:blog)
    blog_default_open_range { SnsConfig::BLOG_DEFAULT_OPEN_RANGES[:to_friends] }
  end
  relation_flg { SnsConfig::RELATION_FLGS[:disable] }
  if Mars::Extension.instance.extension_enabled?(:ranking)
    ranking_display_flg { SnsConfig::RANKING_DISPLAY_FLGS[:view] }
  end
  sns_theme{ SnsTheme.make }
end

SnsTheme.blueprint do
  name {"mars"}
  human_name {"mars"}
end

Page.blueprint do
  title {"タイトル"}
  body {"本文"}
  page_id { Faker.letterify("???") + Time.now.to_i.to_s }
end

Invite.blueprint do
  email { Faker::Internet.email }
  body { "招待状" }
  user { User.make }
  relation { Friendship::RELATIONS[:nothing] }
  contact_frequency { Friendship::CONTACT_FREQUENCIES[:nothing] }
end

SpamIpAddress.blueprint do
  ip_address
end

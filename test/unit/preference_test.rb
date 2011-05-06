require File.dirname(__FILE__) + '/../test_helper'

class PreferenceTest < ActiveSupport::TestCase
  # 初期化時に拡張側のpreferenceが生成されているか
  def test_after_initialize
    pref = Preference.new(:user => User.new)
    pref.preference_associations.map(&:to_s).each do |name|
      assert_not_nil pref.send(name)
    end
  end

  # 指定したメッセンジャーを見られるユーザか
  def test_visible_messenger
    current_user = User.make
    user = User.make
    user.preference.skype_id_visibility = Preference::SKYPE_ID_VISIBILITIES[:publiced]
    user.preference.save!

    assert_equal true, user.preference.visible_messenger?(nil, :skype_id)
    assert_equal true, user.preference.visible_messenger?(current_user, :skype_id)

    user.preference.skype_id_visibility = Preference::SKYPE_ID_VISIBILITIES[:member_only]
    user.preference.save!

    assert_equal false, user.preference.visible_messenger?(nil, :skype_id)
    assert_equal true, user.preference.visible_messenger?(current_user, :skype_id)

    user.preference.skype_id_visibility = Preference::SKYPE_ID_VISIBILITIES[:friend_only]
    user.preference.save!

    assert_equal false, user.preference.visible_messenger?(nil, :skype_id)
    assert_equal false, user.preference.visible_messenger?(current_user, :skype_id)

    current_user.friend!(user)
    assert_equal true, user.preference.visible_messenger?(current_user, :skype_id)
  end
end

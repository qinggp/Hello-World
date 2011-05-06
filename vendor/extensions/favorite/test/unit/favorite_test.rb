require File.dirname(__FILE__) + '/../test_helper'

class FavoriteTest < ActiveSupport::TestCase
  # ユーザ削除時のお気に入り削除チェック
  def test_destroy_related_to_user_record
    favorite_count = Favorite.count
    user = nil
    3.times do
      user = User.make
      2.times do
        Favorite.make(:user_id => user.id)
      end
    end
    assert_equal favorite_count + 6, Favorite.count
    user.destroy
    assert_equal favorite_count + 4, Favorite.count
  end
end

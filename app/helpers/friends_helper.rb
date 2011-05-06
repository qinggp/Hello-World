module FriendsHelper

  # テーブルの要素としてトモダチの画像を表示する際に使用する
  def display_face_photo_on_table(friend, options = { })
    html = ""
    html << content_tag(:div) do
      link_to(display_face_photo(friend.face_photo, :width => options[:width], :height => options[:height]), user_path(friend))
    end
    html << content_tag(:div) do
      div = ""
      friend_count = "(#{friend.friends.size})" if options[:enabled_friend_count]
      div << theme_image_tag("invite.png") if options[:inviter]
      div << link_to(h(friend.name) + "#{friend_count}", user_path(friend))
    end
  end
end

# グループヘルパ
module GroupsHelper

  # 確認画面のForm情報
  def form_params
    if @group.new_record?
      {:url => confirm_before_create_groups_path,
        :model_instance => @group}
    else
      {:url => confirm_before_update_groups_path(:id => @group.id),
        :model_instance => @group}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @group.new_record?
      {:url => groups_path, :method => :post,
        :model_instance => @group}
    else
      {:url => group_path(@group), :method => :put,
        :model_instance => @group}
    end
  end

  # グループにメンバーが所属している場合は解除を、所属していない場合は追加のインターフェースを表示する
  def display_friend_on_group(friend, group)
    friend_on_group = group.group_member?(friend)
    class_name =  friend_on_group  ? "on_group" : "off_group"
    html = ""

    content_tag(:td, :class => class_name, :valign => "top", :width => "80", :align => "center") do
      if friend
        if friend_on_group
          html << link_to(remove_friend_group_path(group, :user_id => friend.id)) do
            target = theme_image_tag("z_down.gif", :border => 0)
            target << "<b>解除</b>"
          end
        else
          html << link_to(add_friend_group_path(group, :user_id => friend.id)) do
            target = theme_image_tag("z_up.gif", :border => 0)
            target << "<b>追加</b>"
          end
        end

        html << link_to(display_face_photo(friend.face_photo, :width => "76"), user_path(friend))
        html << content_tag(:div) do
          link_to(h(friend.name) + "(#{friend.friends.count})", user_path(friend))
        end
      end
    end
  end

  def message_form_params
    {:model_instance => @message,
      :url => confirm_before_create_message_group_path(@group),
      :html => {:method => :post},
      :multipart => true}
  end

  def message_confirm_params
    {:model_instance => @message,
      :url => create_message_group_path(@group),
      :html => {:method => :post}}
  end
end

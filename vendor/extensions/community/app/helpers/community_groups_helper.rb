# コミュニティグループヘルパ
module CommunityGroupsHelper
  include Mars::Community::CommonHelper

  # 確認画面のForm情報
  def form_params
    if @community_group.new_record?
      {:url => confirm_before_create_community_groups_path,
        :model_instance => @community_group}
    else
      {:url => confirm_before_update_community_groups_path(:id => @community_group.id),
        :model_instance => @community_group}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @community_group.new_record?
      {:url => community_groups_path, :method => :post,
        :model_instance => @community_group}
    else
      {:url => community_group_path(@community_group), :method => :put,
        :model_instance => @community_group}
    end
  end

  # グループにコミュニティが所属している場合は解除を、所属していない場合は追加のインターフェースを表示する
  def display_community_on_group(community, group)
    community_on_group = group.has_community?(community)
    class_name =  community_on_group  ? "on_group" : "off_group"
    html = ""

    content_tag(:td, :align => "center", :width => 80, :valign => "top", :class => class_name) do
      if community_on_group
        html << link_to(remove_community_community_group_path(group, :community_id => community.id)) do
          target = theme_image_tag("z_down.gif", :border => 0)
          target << "<b>解除</b>"
        end
      else
        html << link_to(add_community_community_group_path(group, :community_id => community.id)) do
          target = theme_image_tag("z_up.gif", :border => 0)
          target << "<b>追加</b>"
        end
      end

      html <<  link_to(theme_image_tag(community_image_path(community, "thumb"), :width => 76),
                       community_path(community))
      html << content_tag(:div) do
        link_to(h(community.name) + "(#{community.members.count})", community_path(community))
      end
    end
  end
end

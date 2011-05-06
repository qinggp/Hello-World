module CommunityMembersHelper
  include Mars::Community::CommonHelper

  def link_to_assign_sub_admin_with(member, community)
    if member.has_role?("community_admin", community)
      theme_image_tag("community/comm_owner.gif")  + "管理人"
    elsif member.has_role?("community_sub_admin", community)
      theme_image_tag("invite.png") + "副管理人" + "[ "  +
        link_to("解任", remove_from_sub_admin_community_member_path(:id => member.id, :community_id => community.id), :confirm => "副管理人権限を解任します。よろしいですか？")+ " ]"
    elsif member.has_role?("community_general", community)
      link_to("副管理人任命", assign_sub_admin_with_community_member_path(:id => member.id, :community_id => community.id), :confirm => "副管理人に任命します。よろしいですか？")
    end
  end

  def link_to_delegate_admin_to(member, community)
    if member.has_role?("community_admin", community)
      theme_image_tag("community/comm_owner.gif")  + "管理人"
    elsif member.has_role?("community_sub_admin", community)
      theme_image_tag("invite.png") +
        link_to("管理権委譲", delegate_admin_to_community_member_path(:id => member.id, :community_id => community.id), :confirm => "管理権委譲します。よろしいですか？")
    elsif member.has_role?("community_general", community)
      link_to("管理権委譲", delegate_admin_to_community_member_path(:id => member.id, :community_id => community.id), :confirm => "管理権委譲します。よろしいですか？")
    end
  end

  def link_to_dismiss(member, community)
    if member.has_role?("community_admin", community)
      theme_image_tag("community/comm_owner.gif")  + "管理人"
    elsif member.has_role?("community_sub_admin", community)
      if @current_user != member
        theme_image_tag("invite.png") + link_to("強制退会", dismiss_community_member_path(:id => member.id, :community_id => community.id), :confirm => "強制退会させます。よろしいですか？")
      else
        theme_image_tag("invite.png") + "副管理人"
      end
    elsif member.has_role?("community_general", community)
      link_to("強制退会", dismiss_community_member_path(:id => member.id, :community_id => community.id), :confirm => "強制退会させます。よろしいですか？")
    end
  end
end

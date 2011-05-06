require_dependency "#{File.expand_path(File.dirname(__FILE__))}/lib/mars/community/model_extension"

class CommunityExtension < Mars::Extension

  def activate
    ui.my_menus.add :my_community
    ui.main_search_buttons.add :community, :extension => self
    ui.main_menus.add :event_calendar, :extension => self
    ui.main_menus.add :community_search, :extension => self
    ui.friend_menus.add :friend_community, :type => :part, :extension => self
    ui.my_contents[:information].add :new_community_approval, :extension => self
    ui.my_contents[:news].add :community_post, :extension => self
    ui.my_contents[:checklist].add :community_my_post, :extension => self
    ui.my_contents[:misc].add :new_communities, :extension => self
    ui.profile_contents.add :new_community_posts, :extension => self
    ui.navigations.add :community_navigation, :extension => self
    ui.portal_contents[:news].add :community_publiced_post, :extension => self

    ui.mobile_main_menus.add :my_community, :type => :part, :extension => self
    ui.mobile_main_menus.add :event_calendar, :type => :part, :extension => self
    ui.mobile_search_links.add :community_search_link, :url => {:controller => :communities, :action => :search}
    ui.mobile_profile_contents.add :community_list, :type => :part, :extension => self
    ui.mobile_my_home_contents_navigations.add :new_community_post_news, :type => :inline,
      :inline => %Q(<a href="#new_community_post" accesskey="2"><%= emoticon_2 %>コミュニティ最新書込</a>)
    ui.mobile_my_home_contents.add :new_community_approval_news, :extension => self
    ui.mobile_my_home_contents.add :community_post_news, :extension => self
    ui.mobile_portal_news_navigations.add :community_publiced_post,
      :inline => %Q(<a href="#community_news" accesskey="2"><%= emoticon_2 %>コミュニティ最新書込</a>)
    ui.mobile_portal_news.add :community_publiced_post, :extension => self

    User.send(:include, Mars::Community::ModelExtension::User)
  end

  def deactivate
    ui.my_menus.remove :my_community
    ui.main_search_buttons.remove :community
    ui.main_menus.remove :event_calendar
    ui.main_menus.remove :community_search
    ui.friend_menus.remove :friend_community
    ui.my_contents[:news].remove :community_post
    ui.my_contents[:checklist].remove :community_my_post
    ui.my_contents[:misc].remove :new_communities
    ui.profile_contents.remove :new_community_posts
    ui.navigations.remove :community_navigation
    ui.portal_contents[:news].remove :community_publiced_post

    ui.mobile_main_menus.remove :my_community
    ui.mobile_main_menus.remove :event_calendar
    ui.mobile_search_links.remove :community_search_link
    ui.mobile_profile_contents.remove :community_list
    ui.mobile_my_home_contents_navigations.remove :new_community_post_news
    ui.mobile_my_home_contents.remove :new_community_approval_news
    ui.mobile_my_home_contents.remove :community_post_news
    ui.mobile_portal_news_navigations.remove :community_publiced_post
    ui.mobile_portal_news.remove :community_publiced_post
  end
end

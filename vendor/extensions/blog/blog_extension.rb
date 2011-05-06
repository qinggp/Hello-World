require_dependency File.expand_path(File.dirname(__FILE__)) + "/lib/mars/blog/model_extension"

class BlogExtension < Mars::Extension

  def activate
    ui.portal_contents[:news].add :blog_publiced_entries, :extension => self
    ui.my_contents[:news].add :blog_friend_entries, :extension => self
    ui.my_contents[:checklist].add :blog_my_comments, :extension => self
    ui.my_contents[:checklist].add :blog_comments, :extension => self
    ui.my_contents[:checklist].add :blog_my_entries, :extension => self
    ui.profile_contents.add :new_blog_entries, :extension => self
    ui.profile_contents.add :new_comments, :extension => self
    ui.main_search_buttons.add :blog, :extension => self
    ui.main_menus.add :blog_search, :extension => self
    ui.main_menus.add :wom_map, :extension => self
    ui.my_menus.add :my_blog_link, :extension => self
    ui.friend_menus.add :friend_blog, :extension => self, :type => :part
    ui.admin_sns_extension_configs.add :blog_default_open_range, :extension => self

    ui.preferences[:notice].add :blog_comment_notice_acceptable
    ui.preferences[:blog].add :blog
    ui.preferences[:visibility].add :blog_visibility

    ui.mobile_my_home_contents_navigations.add :new_friend_blog, :type => :inline,
      :inline => %Q(<a href="#new_friend_blog" accesskey="1"><%= emoticon_1 %>ブログ新着情報</a>)
    ui.mobile_my_home_contents_navigations.add :new_my_comment, :type => :inline,
      :inline => %Q(<a href="#new_my_comment" accesskey="3"><%= emoticon_3 %>最新ブログコメント</a>)
    ui.mobile_my_home_contents.add :blog_friend_entries_news, :extension => self
    ui.mobile_my_home_contents.add :blog_my_entries_checklist, :extension => self
    ui.mobile_my_home_contents.add :blog_my_comments_checklist, :extension => self
    ui.mobile_my_home_contents.add :blog_comments_checklist, :extension => self
    ui.mobile_main_menus.add :my_blog_link, :type => :part, :extension => self
    ui.mobile_main_menus.add :wom_map, :type => :part, :extension => self
    ui.mobile_search_links.add :blog_search_link, :url => {:controller => :blog_entries, :action => :search}
    ui.mobile_profile_menus.add :new_blog_entries_link, :extension => self
    ui.mobile_profile_contents.add :new_blog_entries, :extension => self
    ui.mobile_portal_news.add :blog_publiced_entries, :extension => self
    ui.mobile_portal_news_navigations.add :blog_publiced_entries,
      :inline => %Q(<a href="#blog_entry_news" accesskey="1"><%= emoticon_1 %>ブログ新着情報</a>)

    Preference.send(:include, Mars::Blog::ModelExtension::Preference)
    User.send(:include, Mars::Blog::ModelExtension::User)
    SnsConfig.send(:include, Mars::Blog::ModelExtension::SnsConfig)
    FriendsController.send(:include, Mars::Blog::ControllerExtension::Friends)
  end

  def deactivate
    ui.portal_contents[:news].remove :blog_publiced_entries
    ui.my_contents[:news].remove :blog_friend_entries
    ui.my_contents[:checklist].remove :blog_my_comments
    ui.my_contents[:checklist].remove :blog_comments
    ui.my_contents[:checklist].remove :blog_my_entries
    ui.profile_contents.remove :new_blog_entries
    ui.profile_contents.remove :new_comments
    ui.main_search_buttons.remove :blog
    ui.main_menus.remove :blog_search
    ui.main_menus.remove :wom_map
    ui.my_menus.remove :my_blog_link
    ui.friend_menus.remove :friend_blog
    ui.admin_sns_extension_configs.remove :blog_default_open_range

    ui.mobile_my_home_contents_navigations.remove :new_friend_blog
    ui.mobile_my_home_contents_navigations.remove :new_my_comment
    ui.mobile_my_home_contents.remove :blog_friend_entries_news
    ui.mobile_my_home_contents.remove :blog_my_entries_checklist
    ui.mobile_my_home_contents.remove :blog_my_comments_checklist
    ui.mobile_my_home_contents.remove :blog_comments_checklist
    ui.mobile_main_menus.remove :my_blog_link
    ui.mobile_main_menus.remove :wom_map
    ui.mobile_search_links.remove :blog_search_link
    ui.mobile_profile_menus.remove :new_blog_entries_link
    ui.mobile_profile_contents.remove :new_blog_entries
    ui.mobile_portal_news.remove :blog_publiced_entries
    ui.mobile_portal_news_navigations.remove :blog_publiced_entries

    ui.preferences[:notice].remove :blog_comment_notice_acceptable
    ui.preferences[:blog].remove :blog
    ui.preferences[:visibility].remove :blog_visibility
  end
end

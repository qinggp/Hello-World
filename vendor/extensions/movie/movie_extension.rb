require_dependency File.expand_path(File.dirname(__FILE__)) + "/lib/mars/movie/model_extension"

class MovieExtension < Mars::Extension
  def activate
    ui.portal_contents[:news].add :publiced_movies, :extension => self
    ui.my_contents[:movielist].add :new_movielist, :extension => self
    ui.main_menus.add :movie, :extension => self
    ui.profile_contents.add :new_movies, :extension => self

    ui.mobile_main_menus.add :movie, :type => :part, :extension => self
    ui.mobile_portal_news.add :publiced_movies, :extension => self
    ui.mobile_portal_news_navigations.add :publiced_movies,
      :inline => %Q(<a href="#movie_news" accesskey="3"><%= emoticon_3 %>ムービー新着情報</a>)

    ui.preferences[:movie].add :movie_default_visibility

    Mars::Movie::ResourceLoader.instance.load
    Preference.send(:include, Mars::Movie::ModelExtension::Preference)
    User.send(:include, Mars::Movie::ModelExtension::User)
  end

  def deactivate
    ui.portal_contents[:news].remove :publiced_movies
    ui.my_contents[:movielist].remove :new_movielist
    ui.main_menus.remove :movie
    ui.profile_contents.remove :new_movies

    ui.mobile_main_menus.remove :movie
    ui.mobile_portal_news.remove :publiced_movies
    ui.mobile_portal_news_navigations.remove :publiced_movies

    ui.preferences[:movie].remove :movie_default_visibility
  end
end

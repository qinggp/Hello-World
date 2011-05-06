require_dependency File.expand_path(File.dirname(__FILE__)) + "/lib/mars/favorite/model_extension"
require_dependency File.expand_path(File.dirname(__FILE__)) + "/lib/mars/favorite/controller_extension"

class FavoriteExtension < Mars::Extension

  def activate
    ui.my_menus.add :favorite, :extension => self, :type => :part

    ui.mobile_main_menus.add :favorite, :type => :inline,
      :inline => "▽<%= link_to('お気に入り', favorites_path) %><br/>"
    ui.mobile_footers.add :add_favorite, :extension => self, :type => :part

    User.send(:include, Mars::Favorite::ModelExtension::User)
  end

  def after_activate
    Mars::Favorite::ControllerExtension.extend_controllers
  end

  def deactivate
    ui.my_menus.remove :favorite

    ui.mobile_main_menus.remove :favorite
    ui.mobile_footers.remove :add_favorite
  end
end

class RankingExtension < Mars::Extension

  def activate
    ui.main_menus.add :ranking, :extension => self
    ui.admin_sns_extension_configs.add :ranking_display_flg, :extension => self
    ui.mobile_main_menus.add :ranking, :type => :part, :extension => self

    SnsConfig.send(:include, Mars::Ranking::ModelExtension::SnsConfig)
    User.send(:include, Mars::Ranking::ModelExtension::User)
  end

  def after_activate
    if RankingExtension.instance.extension_enabled?(:ranking)
      Track.send(:include, Mars::Ranking::ModelExtension::Track)
    end
    if RankingExtension.instance.extension_enabled?(:community)
      Community.send(:include, Mars::Ranking::ModelExtension::Community)
    end
    if RankingExtension.instance.extension_enabled?(:blog)
      BlogEntry.send(:include, Mars::Ranking::ModelExtension::BlogEntry)
      User.send(:include, Mars::Ranking::ModelExtension::UserBlogEntry)
    end
  end

  def deactivate
    ui.main_menus.remove :ranking
    ui.admin_sns_extension_configs.remove :ranking_display_flg
    ui.mobile_main_menus.remove :ranking
  end
end

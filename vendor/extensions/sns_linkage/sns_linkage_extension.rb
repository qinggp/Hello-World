require_dependency File.expand_path(File.dirname(__FILE__)) + "/lib/mars/sns_linkage/model_extension"

class SnsLinkageExtension < Mars::Extension
  
  def activate
    ui.my_contents[:information].add :sns_linkage_notice, :extension => self
    ui.my_contents[:news].add :sns_linkage_news_footer, :extension => self
    ui.navigations.add :sns_linkage_navigation, :extension => self

    ui.mobile_my_home_contents.add :sns_linkage_notice, :extension => self
    User.send(:include, Mars::SnsLinkage::ModelExtension::User)
  end
  
  def deactivate
    ui.my_contents[:information].remove :sns_linkage_notice
    ui.my_contents[:news].remove :sns_linkage_news_footer
    ui.navigations.remove :sns_linkage_navigation

    ui.mobile_my_home_contents.remove :sns_linkage_notice
  end
end

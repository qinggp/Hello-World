class <%= class_name %> < Mars::Extension
  
  def activate
    # ui.my_contents.add :<%= extension_name.underscore %>, :partial => "", :helper => ""
    # ui.profile_contents.add :<%= extension_name.underscore %>, :partial => "", :helper => ""
    # ui.my_menus.add :<%= extension_name.underscore %>, :url => {:controller => ""}
  end
  
  def deactivate
    # ui.my_contents.remove :<%= extension_name.underscore %>
    # ui.profile_contents.remove :<%= extension_name.underscore %>
    # ui.my_menus.remove :<%= extension_name.underscore %>
  end
  
end

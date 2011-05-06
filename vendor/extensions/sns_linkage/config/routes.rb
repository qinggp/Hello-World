ActionController::Routing::Routes.draw do |map|
  map.resources :sns_linkages,
  :collection => {
    :help => :get,
    :publish_link_key => :put,
    :unpublish_link_key => :get,
    :news => :get,
    :info => :get,
  }

  # SNS連携用のAPI
  map.connect 'sns_linkage_api/?:key', :controller => :sns_linkage_api, :action => "show"
  map.connect 'sns_linkage_api', :controller => :sns_linkage_api, :action => "show"
end

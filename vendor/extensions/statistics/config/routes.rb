ActionController::Routing::Routes.draw do |map|
  # map.resources xxxx
  map.namespace :admin do |admin|
    admin.resources :statistics
  end

end

ActionController::Routing::Routes.draw do |map|
  map.resources :tracks, :collection => {
    :search => :post
  }
end

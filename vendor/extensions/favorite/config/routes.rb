ActionController::Routing::Routes.draw do |map|
  map.resources :favorites, :collection => {
    :confirm_before_create => :post,
    :confirm_before_update => :post,
    :destroy_checked => :post,
  },
  :member => {
    :complete_after_create => :get,
    :complete_after_update => :get,
    :confirm_before_destroy => :get,
    :confirm_before_destroy_by_footer => :get,
  }
end

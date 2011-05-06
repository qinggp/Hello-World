ActionController::Routing::Routes.draw do |map|
  map.namespace :admin do |admin|
  admin.resources :banners ,:collection => {
      :confirm_before_create => :post,
      :confirm_before_update => :post,
      :show_unpublic_image_temp => :get,
    },
    :member => {
      :complete_after_create => :get,
      :complete_after_update => :get,
      :show_unpublic_flash => :get,
      :show_unpublic_image => :get
    }
  end
end

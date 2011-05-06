ActionController::Routing::Routes.draw do |map|
  map.resources :movies, :collection => {
      :confirm_before_create => :post,
      :confirm_before_update => :post,
      :search => [:get, :post],
      :failure_not_found => :get,
      :failure_upload => :get,
      :my_status => :get,
      :select_map => :get,
      :map => :get,
      :index_for_recent => :get,
      :about_packet => :get,
      :index_for_map => :get,
      :map_for_mobile => :get,
      :show_calendar => :get,
    },
    :member => {
      :complete_after_create => :get,
      :complete_after_update => :get,
      :confirm_before_destroy => :get,
      :thumbnail => :get,
      :mobile_thumbnail => :get,
      :flash_file => :get,
      :mobile_3gp_file => :get,
      :mobile_3g2_file => :get,
      :my_show => :get,
    }

  map.resources :users do |user|
    user.resources :movies, :collection => {
      :index_for_user => :get
    }
  end
end

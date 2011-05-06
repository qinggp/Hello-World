ActionController::Routing::Routes.draw do |map|
  map.resources :schedules,
  :new => {
    :confirm_before_create => :post
  },
  :member => {
    :confirm_before_update => :post,
    :complete_after_create => :get,
    :complete_after_update => :get,
    :confirm_before_destroy => :get,
    :complete_after_destroy => :get
  },
  :collection => {
    :show_calendar => :get,
    :show_list => :get
  }
end

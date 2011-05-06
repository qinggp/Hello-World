ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'sessions', :action => 'new'
  map.forgot_password '/forgot_password', :controller => 'forgot_passwords', :action => 'new'
  map.change_password '/change_password/:reset_code', :controller => 'forgot_passwords', :action => 'reset'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.admin '/admin', :controller => 'admin/welcome', :action => 'index'

  map.resource :session
  map.resources :forgot_passwords
  map.resources :sessions,
  :collection => {
    :failed_login => :get,
    :create_with_mobile_ident => :post,
  }
  map.resources :users,
  :collection => {
    :search_index => :get,
    :edit_openid => :get,
    :confirm_before_update_openid => :post,
    :update_openid => :get,
    :complete_after_update_openid => :get,
    :open_id_authentication_for_update => :get,
    :show_calendar => :get,
    :search_member => [:get, :post],
    :confirm_before_create => :post, :confirm_before_update => :post,
    :show_unpublic_image_temp => :get,
    :show_face_photo => :get,
    :prepared_face_photo_choices => :get,
    :nickname_unique_check => :get,
    :search_zipcode => :get,
    :edit_request_new_name => :get,
    :confirm_before_request_new_name => :post,
    :request_new_name => :post,
    :complete_after_request_new_name => :get,
    :my_home => :get,
    :search_member_form => :get,
    :search_member => [:post, :get],
    :edit_id_password => :get,
    :confirm_before_update_id_password => :post,
    :update_id_password => :put,
    :edit_for_leave => :get,
    :confirm_before_leave => :post,
    :leave => :delete,
    :complete_after_leave => :get,
    :edit_mobile_email => :get,
    :confirm_before_update_mobile_email => :post,
    :update_mobile_email => :put,
    :edit_mobile_ident => :get,
    :update_mobile_ident => :put,
    :set_mobile_ident => :put,
    :release_mobile_ident => :put,
    :complete_after_mobile_ident => :get,
    :failed_new => :get,
    :failed_new_invalid_url => :get,
    :failed_new_invitation_only => :get,
    :failed_deactive => :get,
    :failed_deactive_by_pause => :get,
    :news_index => :get,
  },
  :member => {
    :complete_after_create => :get,
    :complete_after_update => :get,
    :complete_after_update_id_password => :get,
    :complete_after_update_mobile_email => :get,
    :edit_friend_description => :get,
    :update_friend_description => :put,
    :clear_friend_description => :put,
    :confirm_before_update_friend_description => :post,
    :complete_after_update_friend_description => :get,
    :confirm_before_clear_friend_description => :get,
    :complete_after_clear_friend_description => :get,
    :new_friend_application => :get,
    :create_friend_application => :post,
    :recreate_friend_application => :post,
    :approve_friend => :post,
    :reject_friend_application => :post,
    :new_approve_friend => :get, 
    :confirm_before_approve_friend => :post, 
    :confirm_before_reject_friend_application => :get,
    :new_friend_application => :get, 
    :confirm_before_create_friend_application => :post,
    :create_friend_application => :post,
  }

  map.resource :qrcode

  map.resources :preferences, :collection => {
    :confirm_before_create => :post,
    :confirm_before_update => :post,
    :update_home_layout_type => :put,
    :confirm_before_create => :post, :confirm_before_update => :post
  },
  :member => {
    :complete_after_create => :get,
    :complete_after_update => :get
  }

  map.resources :messages,
  :collection => {
    :search_inbox => [:get, :post],
    :search_outbox => [:get, :post],
    :confirm_before_create => :post,
    :complete_after_create => :get,
    :show_unpublic_image_temp => :get
  },
  :member => {
    :show_received_message => :get,
    :show_unpublic_image => :get,
    :delete => :put,
    :confirm_before_delete => :get
  }

  map.resources :friends,
  :collection => {
    :maintenance => :get,
    :list_request => :get,
  },
  :member => {
    :confirm_before_break_off => :get,
    :break_off => :delete,
  }
  map.resources :users do |user|
    user.resources :friends,
    :collection => {
      :list_description => :get,
      :new_message => :get,
      :confirm_before_create_message => :post,
      :create_message => :post,
      :complete_after_create_message => :get,
      :index_for_invite => :get,
      :index => :get,
    }
  end

  map.resources :groups,
  :collection => {
    :confirm_before_create => :post,
    :confirm_before_update => :post,
    :show_unpublic_image_temp => :get,
    :complete_after_destroy => :get
  },
  :member => {
    :member_list => :get,
    :complete_after_create => :get,
    :complete_after_update => :get,
    :add_friend => :get,
    :remove_friend => :get,
    :new_message => [:get, :post],
    :confirm_before_create_message => :post,
    :create_message => :post,
    :complete_after_create_message => :get,
    :confirm_before_destroy => :get
  }

  map.resources :informations,
  :collection => {
    :index_for_important => :get,
  }
  map.resources :invites,
  :collection => {
    :confirm_before_create => :post,
    :confirm_before_update => :post,
    :reinvite_all => :get,
    :constitution => :get,
  },
  :member => {
    :complete_after_create => :get,
    :complete_after_update => :get,
    :confirm_before_destroy => :get,
  }
  map.resources :asks,
  :collection => {
    :confirm_before_create => :post,
    :complete_after_create => :get,
  }

  map.resources :pages

  map.namespace "admin" do |admin|
    admin.resources :announcements,
    :member => {
      :complete_after_create => :get,
      :complete_after_update => :get,
      :confirm_before_update => :post
    },
    :collection => {:confirm_before_create => :post}

    admin.resources :users, :collection => {
      :wrote_administration_face_photo => :get,
      :index_for_approval => :get,
    },
    :member => {
      :delete => :get,
      :edit_passwd => :get,
      :update_passwd => :put,
      :confirm_before_update => :post,
      :confirm_before_destroy => :post,
      :confirm_before_update_passwd => :post,
      :complete_after_update => :get,
      :complete_after_update_passwd => :get,
      :face_photo_destroy => :delete,
      :show_unpublic_image => :get,
      :show_unpublic_image_temp => :get,
      :dispatch_for_approval => [:post, :put],
      :approve => :get,
      :rewrite_request => :get,
      :reject => :get,
    },
    :new => {
      :complete_after_destroy => :get
    }

    admin.resources :pages,
    :collection => {
      :confirm_before_update => :post,
      :image_management => :get,
      :image_destroy => :get,
      :image_upload => :post,
      :show_public_image => :get
    },
    :member => {
      :complete_after_update => :get

    }

    admin.resources :sns_configs,
    :collection => {
      :select_map => :get,
    },
    :member => {
      :confirm_before_update => :post,
      :complete_after_update => :get
    }
    admin.resources :contents, :collection => {
      :search_top => :get,
    }
    admin.resources :invites
  end
end

ActionController::Routing::Routes.draw do |map|
  map.resources :users do |user|
    user.resources :blog_entries, :collection => {
      :index_for_user => [:get, :post],
      :spread_backnumber => :get,
      :search_for_user_mobile => [:get, :post],
      :backnumber_mobile => :get,
      :show_calendar => :get,
      :prepared_face_photo_choices => :get,
      :index_feed_for_user => :get
    }
    user.resources :blog_entries_admin, :collection => {
      :search => [:get, :post],
      :update_checked => [:get, :post],
      :destroy_checked => [:get, :post],
      :all_checked => [:get, :post],
      :confirm_before_update_checked => [:get, :post],
      :confirm_before_destroy_checked => [:get, :post],
    }
    user.resources :blog_categories, :collection => {
      :confirm_before_create => :post,
      :confirm_before_update => :post,
    },
    :member => {
      :complete_after_create => :get,
      :complete_after_update => :get,
      :confirm_before_destroy => :get,
    }
  end

  map.resources :blog_entries, :collection => {
      :confirm_before_create => :post,
      :confirm_before_update => :post,
      :search => [:get, :post],
      :search_for_friends => [:get, :post],
      :show_unpublic_image_temp => :get,
      :map => :get,
      :index_for_map => :get,
      :map_for_mobile => :get,
      :not_friend_error => :get,
      :index_feed => :get,
      :select_map => :get,
    },
    :member => {
      :complete_after_create => :get,
      :complete_after_update => :get,
      :confirm_before_destroy => :get,
      :show_unpublic_image => :get
    }

  map.resources :blog_entries do |blog|
    blog.resources :blog_comments, :collection => {
      :confirm_before_create => :post,
      :confirm_before_update => :post,
    },
    :member => {
      :complete_after_create => :get,
      :complete_after_update => :get,
      :confirm_before_destroy => :get
    }
  end

  map.resources :friends,
  :member => {
    :change_new_blog_entry_displayed => :get
  }

  map.namespace :admin do |admin|
    admin.resources :blog_categories, :collection => {
      :confirm_before_create => :post,
      :confirm_before_update => :put,
    },
    :member => {
      :complete_after_create => :get,
      :complete_after_update => :get,
    }
    admin.resources :blog_entries, :collection => {
      :wrote_administration_blog_comments => :get,
      :wrote_administration_blog_entries => :get,
    },
    :member => {
      :admin_blog_attachment_destroy => :delete
    }
  end

  # NOTE: クチコミマップのRSS2.0は、連携しているサイトがあるため、旧アドレスをマッピングさせる
  map.connect '/blog/feed/rss.php',
              :controller => 'blog_entries',
              :action => 'map',
              :format => 'rss'

  # 以前の各ブログへのURLでアクセスがあった場合のルーティング
  map.connect '/blog/blog.php',
              :controller => 'blog_entries',
              :action => 'relate_old_blog_id_to_current'

  # 以前のユーザブログトップへのURLでアクセスがあった場合のルーティング
  map.connect '/blog',
              :controller => 'blog_entries',
              :action => 'relate_old_user_id_to_current'
end

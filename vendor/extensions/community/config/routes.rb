ActionController::Routing::Routes.draw do |map|
  map.resources :communities, :collection => {
    :search => :get,
    :display_file => :get,
    :show_unpublic_image_temp => :get,
    :index_feed => :get,
    :recent_posts => :get,
    :select_map => :get,
  },
  :new => {
    :confirm_before_create => :post,
    :complete_after_destroy => :get
  },
  :member => {
    :confirm_before_update => :post,
    :confirm_before_destroy => :post,
    :complete_after_create => :get,
    :complete_after_update => :get,
    :confirm_before_apply => :get,
    :apply => :post,
    :confirm_before_cancel => :get,
    :cancel => :post,
    :show_application => :get,
    :approve_or_reject => :post,
    :display_file => :get,
    :show_detail => :get,
    :show_members => [:get, :post],
    :show_unpublic_image => :get,
    :index_feed_for => :get,
    :new_message => [:get, :post],
    :confirm_before_create_message => :post,
    :create_message => :post,
    :complete_after_create_message => :get,
    :update_comment_notice_acceptable => :post,

  }

  map.resources :communities do |community|
    community.resources :threads, :controller => "community_threads",
    :collection => {
      :search => [:get, :post],
      :show_comment_tree => :get
    },
    :member => {
      :show_comment_tree_specified_thread => :get
    }
  end

  map.resources :communities do |community|
    community.resources :linkages, :controller => "community_linkages",
    :collection => {
      :index_for_admin => :get,
      :confirm_before_create => :post,
      :destroy_checked_ids => :delete,
      :complete_after_destroy => :get,
    },
    :member => {
      :complete_after_create => :get,
      :confirm_before_destroy => :get,
    }
  end

  map.resources :community_memberships,
  :member => {
    :change_new_comment_displayed => :get,
    :change_comment_notice_acceptable => :get,
    :change_comment_notice_acceptable_for_mobile => :get
  }

  map.resources :community_groups,
  :collection => {
    :confirm_before_create => :post,
    :confirm_before_update => :post,
    :complete_after_destroy => :get,
  },
  :member => {
    :community_list => :get,
    :complete_after_create => :get,
    :complete_after_update => :get,
    :confirm_before_destroy => :get,
    :add_community => :get,
    :remove_community => :get,
  }

  map.resources :communities do |community|
    community.resources :map_categories, :controller => "community_map_categories", :new => {
      :new => :post
    },
    :collection => {
      :confirm_before_create => :post,
      :confirm_before_update => :post,
      :complete_after_destroy => :get,
    },
    :member => {
      :complete_after_create => :get,
      :complete_after_update => :get,
      :confirm_before_destroy => :post,
    }
  end

  map.connect 'communities/open_map',
  :controller => "communities",
  :action => "open_map"

  map.resources :communities do |community|
    community.resources :members, :controller => "community_members",
    :member => {
      :dismiss => :get,
      :confirm_before_dismiss => :get,
      :assign_sub_admin_with => :get,
      :confirm_before_assign_sub_admin_with => :get,
      :delegate_admin_to => :get,
      :confirm_before_delegate_admin_to => :get,
      :remove_from_sub_admin => :get,
      :confirm_before_remove_from_sub_admin => :get
    }
  end

  map.resources :communities do |community|
    community.with_options(:new => {:confirm_before_create => :post},
                           :collection => {:show_unpublic_image_temp => :get},
                           :member => {
                             :complete_after_create => :get,
                             :confirm_before_update => :post,
                             :complete_after_update => :get,
                             :confirm_before_destroy => :get,
                             :show_unpublic_image => :get}) do |opt|
      opt.resources :events, :controller => "community_events"
      opt.resources :topics, :controller => "community_topics"
      opt.resources :markers, :controller => "community_markers"
    end
  end

  map.resources :community_events, :collection => {
    :show_calendar => :get,
    :list_on_date => :get,
  }

  [:community_events, :community_topics, :community_markers].each do |item|
    map.resources item do |thread|
      thread.with_options(:controller => "community_replies",
                          :collection => {
                            :confirm_before_create => :post,
                            :confirm_before_update => :post,
                            :show_unpublic_image_temp => :get
                          },
                          :member => {
                            :complete_after_create => :get,
                            :complete_after_update => :get,
                            :confirm_before_destroy => :get,
                            :show_unpublic_image => :get}) do |opt|
        opt.resources :replies, :controller => "community_replies"
      end
    end
  end

  map.resources :community do |community|
    community.resources :markers, :controller => "community_markers", :collection => {
      :map => :get,
      :list_category => :get,
      :map_for_mobile => :get
    }
  end

  map.resources :community do |community|
    community.resources :events, :controller => "community_events", :member => {
      :show_members => :get,
    }
  end

  map.resources :community_member_messages, :member => {
    :new_message => :get,
    :confirm_before_create_message => :post,
    :create_message => :post,
    :complete_after_create_message => :get,
  }

  # Adobe AirからアクセスされるAPI

  # ログインユーザの所属しているコミュニティの全てのトピック＋それへの返信を取得
  # GET /community_comments.atom?count=20&page=2
  map.connect "/community_comments.:format",
  :controller => :community_replies, :action => :index,
  :conditions => {:method => :get}

  # コミュニティ指定によるコメントの取得
  # GET /communities/:community_id/community_comments.atom?count=20&page=2
  map.connect "/communities/:community_id/community_comments.:format",
  :controller => :community_replies, :action => :index,
  :conditions => {:method => :get}

  # トピック指定によるコメントの取得
  # GET /community_topics/:topic_id/community_comments.atom?count=20&page=2
  map.connect "/community_topics/:topic_id/community_comments.:format",
  :controller => :community_replies, :action => :index,
  :conditions => {:method => :get}

  # トピックに対するコメントの投稿
  # POST /community_topics/:topic_id/community_comments.atom
  map.connect "/community_topics/:topic_id/community_comments.:format",
  :controller => :community_replies, :action => :create,
  :conditions => {:method => :post}

  # トピックのコメントに対する返信
  # POST /community_comments/:parent_id/community_comments.atom
  map.connect "/community_comments/:parent_id/community_comments.:format",
  :controller => :community_replies, :action => :create,
  :conditions => {:method => :post}

  map.resources :community_replies

  map.namespace :admin do |admin|
    admin.resources :community_categories, :collection => {
      :confirm_before_create => :post,
      :confirm_before_update => :post,
      :map_category_list => :get,
      :map_category_confirm_before_update => :post,
    },
    :member => {
      :complete_after_create => :get,
      :complete_after_update => :get,
      :sub_category_list => :get,
      :sub_category_edit => :get,
      :map_category_edit => :get,
      :map_category_update => :put
    },
    :new => {
      :sub_category_new => :get,
    }
    admin.resources :communities, :collection => {
      :confirm_before_update => :post,
      :wrote_administration_communities => :get,
      :wrote_administration_topics => :get,
      :wrote_administration_events => :get,
      :show_unpublic_image_temp => :get
    },
    :member => {
      :complete_after_create => :get,
      :complete_after_update => :get,
      :sub_category_list => :get,
      :sub_category_edit => :get,
      :map_category_edit => :get,
      :map_category_update => :put
    },
    :new => {
      :sub_category_new => :get,
    }
    admin.resources :communities, :collection => {
      :confirm_before_update => :post,
      :wrote_administration_communities => :get,
      :wrote_administration_topics => :get,
      :wrote_administration_events => :get,
      :show_unpublic_image_temp => :get
    },
    :member => {
      :complete_after_update => :get,
      :confirm_before_destroy => :post,
      :community_file_destroy => :delete,
      :community_thread_file_destroy => :delete,
      :community_reply_file_destroy => :delete,
      :community_event_file_destroy => :delete,
    },
    :new => {
      :complete_after_destroy => :get
    }
  end
end

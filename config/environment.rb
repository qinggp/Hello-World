# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require "mars"
require 'mars/initializer'

CONFIG = YAML::load_file(File.join(RAILS_ROOT, "config", "settings.yml"))[RAILS_ENV]

Mars::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem "highline", :version => '1.5.0'
  config.gem 'pg', :version => '0.8.0'
  config.gem 'mislav-will_paginate', :lib => 'will_paginate', :version => '2.3.11'
  config.gem 'ttilley-aasm', :lib => 'aasm', :version => '2.1.1'
  config.gem 'rqrcode', :version => '0.3.2'
  config.gem "ruby-openid", :version => '2.1.7', :lib => "openid"
  config.gem "fastercsv", :version => '1.5.0'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  # config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]


  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address => 'localhost',
    :port => 25,
    :domain => 'localdomain'
  }
  config.action_mailer.default_charset = 'iso-2022-jp'

  config.i18n.default_locale = :ja

  config.action_controller.session_store = :active_record_store

  # エラーラッピングの無効化
  config.action_view.field_error_proc = Proc.new{|html_tag, instance| html_tag }

  # メニュー等の並びを指定
  config.ui.main_menus.sequences = [:home, :wom_map, :event_calendar, :movie, :member_search, :blog_search, :community_search, :invite, :ranking]
  config.ui.my_menus.sequences = [:my_home, :my_blog_link,  :my_message, :my_schedule, :my_friend, :my_community, :favorite, :track, :profile, :edit_preference]
  config.ui.friend_menus.sequences = [:friend_home, :friend_message, :friend_blog, :friend_schedule, :friend_list, :friend_community]
  config.ui.profile_contents.sequences = [:new_blog_entries, :new_movies, :new_community_posts, :new_comments, :friend_description]
  config.ui.navigations.sequences = [:schedule_calendar_navigation, :friend_navigation, :community_navigation, :sns_linkage_navigation]
  config.ui.admin_sns_extension_configs.sequences = [:blog_default_open_range, :ranking_display_flg]

  # 検索ボタン
  config.ui.main_search_buttons.sequences = [:blog, :community]

  # 携帯サイト用
  config.ui.mobile_main_menus.sequences =
    [:important_information, :my_message, :my_blog_link, :movie, :my_community, :favorite,
     :event_calendar, :search_index, :my_schedule, :my_friends,
     :track, :invite, :ranking, :wom_map, :information]
  config.ui.mobile_my_home_contents.sequences =
    [:new_community_approval_news, :new_message, :sns_linkage_notice,
     :blog_friend_entries_news, :blog_comments_checklist, :community_post_news, :blog_my_comments_checklist]
  config.ui.mobile_my_home_contents_navigations.sequences = [:new_friend_blog, :new_community_post_news, :new_my_comment]
  config.ui.mobile_search_links.sequences = [:user_search_link, :blog_search_link, :community_search_link]
  config.ui.mobile_footers.sequences = [:add_favorite]
  config.ui.mobile_profile_menus.sequences = [:friend_description_list, :send_message, :new_blog_entries_link, :friend_schedule_link]
  config.ui.mobile_profile_contents.sequences = [:new_blog_entries, :community_list]
  config.ui.mobile_portal_menus.sequences = [:information, :search_index, :news_index]
  config.ui.mobile_portal_news_navigations.sequences = [:blog_publiced_entries, :community_publiced_post, :publiced_movies]
  config.ui.mobile_portal_news.sequences = [:blog_publiced_entries, :community_publiced_post, :publiced_movies]

  # 個人設定
  config.ui.init_preferences :notice, :visibility, :my_home, :blog, :movie, :messenger
  config.ui.preferences[:notice].sequences =
    [:message_notice_acceptable, :blog_comment_notice_acceptable, :notification_track_count]
  config.ui.preferences[:visibility].sequences = [:profile_restraint_type, :blog_visibility, :schedule_visibility]
  config.ui.preferences[:blog].sequences = [:blog]
  config.ui.preferences[:messenger].sequences = [:skype_messenger, :yahoo_messenger]
  config.ui.mobile_preference_sequences = [:notice, :visibility, :blog, :movie] # 携帯用

  # トップページの自分のコンテンツ
  config.ui.init_my_contents :information, :news, :checklist, :movielist, :misc
  config.ui.my_contents[:information].sequences =
    [:information, :new_friend_application, :new_community_approval, :new_message, :sns_linkage_notice]
  config.ui.my_contents[:news].sequences =
    [:blog_friend_entries, :blog_comments, :community_post, :sns_linkage_news_footer]
  config.ui.my_contents[:checklist].sequences =
    [:blog_my_comments, :blog_comments, :blog_my_entries, :community_my_post]
  config.ui.my_contents[:movielist].sequences = [:new_movielist]
  config.ui.my_contents[:misc].sequences = [:new_users, :new_communities]

  # ポータルページのコンテンツ
  config.ui.init_portal_contents :information, :news
  config.ui.portal_contents[:news].sequences =
    [:blog_publiced_entries, :community_publiced_post, :publiced_movies]

  # ポータルページのナビゲーション
  config.ui.portal_navigations.sequences = [:schedule_calendar_navigation]
end

# RSS1.0追加
Mime::Type.register "application/rdf+xml", :rdf

# OpenIDのRP-OP間SSL通信時の証明書検証リスト指定
# NOTE: システムデフォルトのcrtを使用。OSによって場所が違うこともある
OpenID.fetcher.ca_file = '/etc/ssl/certs/ca-certificates.crt' if defined? OpenID

# file_columnでは、日本語のファイル名がアップロードできないので、サニタイズ部分を書き換える
FileColumn.send(:include, Mars::FileColumn)

# file_coliumnでは、PDFもサイズ変換を行うが、必要ないのでしないようにする
FileColumn::BaseUploadedFile.send(:include, Mars::MagickFileColumn)

# OpenIDでも自動ログインできるようにするため、認証後のリダイレクトするURLにrememberパラメータを追加
OpenIdAuthentication.send(:include, Mars::OpenIdAuthentication)

ActionView::Helpers::TextHelper.send(:include, Mars::ActionView::Helpers::TextHelper)

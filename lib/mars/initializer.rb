require 'initializer'
require 'mars/extension'
require 'mars/extension/loader'
require 'mars/ui'

# このファイルはRadiantCMSの lib/radiant/initializer.rb を参考にしています．
module Mars

  # Rails の Configuration クラスを継承しています．
  #
  # 拡張機能用の処理を追加しています．
  class Configuration < Rails::Configuration
    attr_accessor :extension_paths
    attr_writer :extensions
    attr_accessor :view_paths
    attr_accessor :extension_dependencies

    def initialize
      self.view_paths = []
      self.extension_paths = default_extension_paths
      self.extension_dependencies = []
      super
    end

    # UI設定オブジェクト取得
    def ui
      Mars::UI.instance
    end

    # exntetoin が配置されるデフォルトディレクトリ
    def default_extension_paths
      paths = [RAILS_ROOT + '/vendor/extensions']
      # NOTE: テスト用の extensions にパスを通す
      #       config/environments/test.rb で再定義しても遅いためココに記述
      # FIXME: この部分から追い出したい
      paths.unshift(RAILS_ROOT + "/test/fixtures/extensions") if RAILS_ENV == "test"
      paths
    end

    # 全ての extension 名一覧
    def extensions
      @extensions ||= all_available_extensions
    end

    # 利用する extension を定義
    def extension(ext)
      @extension_dependencies << ext unless @extension_dependencies.include?(ext)
    end

    # 利用する extension が active になっているかチェック
    def check_extension_dependencies
      unloaded_extensions = []
      @extension_dependencies.each do |ext|
        extension = ext.camelcase + 'Extension'
        begin
          extension_class = extension.constantize
          unloaded_extensions << extension unless defined?(extension_class) && (extension_class.instance.active?)
        rescue NameError
          unloaded_extensions << extension
        end
      end
      if unloaded_extensions.any?
        abort <<-end_error
Missing these required extensions:
#{unloaded_extensions}
end_error
      else
        return true
      end
    end

    private
    def all_available_extensions
      extension_paths.map do |path|
        Dir["#{path}/*"].select {|f| File.directory?(f) }
      end.flatten.map {|f| File.basename(f).sub(/^\d+_/, '') }.sort.map(&:to_sym)
    end
  end

  # Rails の Initializer クラスを継承しています．
  # see rails-2.x.x/lib/initializer.rb
  #
  # 拡張機能用の処理を追加しています． environment.rb では
  # Rails::Initializer.run ではなく， Mars::Initializer.run で設定を記
  # 述します．
  class Initializer < Rails::Initializer
    def self.run(command = :process, configuration = Configuration.new)
      Rails.configuration = configuration
      super
    end

    # extension のリセットを autoload のクラスクリア時に実行．
    # NOTE: development環境でのみ使用してください．
    def reset_extensions_at_autoload_clear
      # NOTE & FIXME:
      # リクエストを受け取るときにも再クリアする。
      # 前回のクリア時のactivateの際に、誤ってロードしてしまうクラスが
      # あるからである。できれば一度ですませたい。
      ::ActionController::Dispatcher.prepare_dispatch do
        ::ActiveSupport::Dependencies.clear
      end

      ::ActiveSupport::Dependencies.module_eval do
        def clear_with_reset_extension
          ::Mars::Extension::Loader.instance.deactivate_extensions
          clear_without_reset_extension
          ::Mars::Extension::Loader.instance.load_extensions
          ::Mars::Extension::Loader.instance.activate_extensions
        end

        alias_method :clear_without_reset_extension, :clear
        alias_method :clear, :clear_with_reset_extension
      end
    end

    # extension 内の public ファイルに symlink を貼ります。
    def set_extensions_public_symlink
      extension_names = self.configuration.extensions.map{|e| e.to_s.downcase }
      extension_public_dirs = [extension_loader.image_paths, extension_loader.stylesheet_paths, extension_loader.javascript_paths]
      extension_names.each do |ename|
        %w(images stylesheets javascripts).zip(extension_public_dirs) do |pub_dir, ext_dirs|
          from = File.join(Rails.public_path, pub_dir, ename)
          begin
            File.delete(from) if File.symlink?(from)
          rescue Errno::ENOENT
            # NOTE: すでにシンボリックリンクが存在しないのに削除しようとした場合の例外を無視
          end
          to = ext_dirs.detect{|path| File.basename(path) == ename}
          begin
            File.symlink(to, from) if !to.nil? && !File.exist?(from)
          rescue Errno::EEXIST
            # NOTE: すでにファイルが存在した場合、何もしない
          end
        end
      end
    end

    # extension 内の theme ファイルに symlink を貼ります。
    #
    # ==== 備考
    #
    # public に上げられている themes ディレクトリ内部にシンボリックリンクを張る
    def set_extensions_theme_symlink
      extension_names = self.configuration.extensions.map{|e| e.to_s.downcase }
      themes = Dir.glob("#{Rails.public_path}/themes/*").map{|t| t.split( File::Separator )[-1]}
      themes.each do |theme|
        extension_theme_dirs = [extension_loader.theme_image_paths(theme),
                                extension_loader.theme_stylesheet_paths(theme),
                                extension_loader.theme_javascript_paths(theme)]
        extension_names.each do |ename|
          %w(images stylesheets javascripts).map{|d| "themes/#{theme}/#{d}" }.zip(extension_theme_dirs) do |theme_dir, ext_theme_dirs|
            [File.join(Rails.public_path, theme_dir, ename), File.join(Rails.root, theme_dir, ename)].each do |from|
              begin
                File.delete(from) if File.symlink?(from)
              rescue Errno::ENOENT
                # NOTE: すでにシンボリックリンクが存在しないのに削除しようとした場合の例外を無視
              end
              to = ext_theme_dirs.detect{|path| File.basename(path) == ename}
              begin
                File.symlink(to, from) if !to.nil? && !File.exist?(from)
              rescue Errno::EEXIST
                # NOTE: すでにファイルが存在した場合、何もしない
              end
            end
          end
        end
      end
    end

    # extension も含めたフレームワークのビューパスを初期化
    def initialize_framework_views
      if configuration.frameworks.include?(:action_view)

        view_paths = [].tap do |arr|
          # view_path を追加
          arr << configuration.view_path if !configuration.view_paths.include?(configuration.view_path)
          # 通常の view_paths を追加
          arr.concat(configuration.view_paths)
          # extension の view_paths を追加
          arr.concat(extension_loader.view_paths)
          arr.reverse!
        end
        if configuration.frameworks.include?(:action_mailer) || defined?(ActionMailer::Base)
          ::ActionMailer::Base.view_paths = ::ActionView::Base.process_view_paths(view_paths)
        end
        if configuration.frameworks.include?(:action_controller) || defined?(ActionController::Base)
          ActionController::Base.view_paths.clear
          view_paths.each do |vp|
            ActionController::Base.prepend_view_path vp
          end
        end
      end
    end

    # UIの初期化
    def initialize_default_ui
      configuration.ui.clear
      initialize_default_ui_for_pc
      initialize_default_ui_for_mobile
    end

    private

    # autoload のパス設定
    def set_autoload_paths
      extension_loader.add_extension_paths
      super
    end

    # plugin のパス設定
    def add_plugin_load_paths
      extension_loader.add_plugin_paths
      super
    end

    def load_plugins
      super
      extension_loader.load_extensions
    end

    def after_initialize
      super
      extension_loader.activate_extensions
      configuration.check_extension_dependencies
    end

    def initialize_routing
      extension_loader.add_controller_paths
      super
      extension_loader.add_routing_configuration_files
      ActionController::Routing::Routes.add_configuration_file(File.join(RAILS_ROOT, "config", "last_loaded_routes.rb"))
      ActionController::Routing::Routes.reload!
    end

    def initialize_metal
      Rails::Rack::Metal.metal_paths += extension_loader.metal_paths
      super
    end

    def initialize_i18n
      extension_loader.add_i18n_locale_paths
      super
    end

    def extension_loader
      ext = Extension::Loader.instance
      ext.initializer ||= self
      return ext
    end

    # PC用のUI設定
    def initialize_default_ui_for_pc
      configuration.ui.main_menus.add :home
      configuration.ui.main_menus.add :member_search
      configuration.ui.main_menus.add :invite
      configuration.ui.my_menus.add :my_home
      configuration.ui.my_menus.add :edit_preference
      configuration.ui.my_menus.add :profile
      configuration.ui.my_menus.add :my_message
      configuration.ui.my_menus.add :my_friend
      configuration.ui.friend_menus.add :friend_home
      configuration.ui.friend_menus.add :friend_message
      configuration.ui.friend_menus.add :friend_list
      configuration.ui.my_contents[:information].add :new_message
      configuration.ui.my_contents[:information].add :information
      configuration.ui.my_contents[:information].add :new_friend_application
      configuration.ui.my_contents[:misc].add :new_users
      configuration.ui.preferences[:visibility].add :profile_restraint_type
      configuration.ui.preferences[:notice].add :message_notice_acceptable
      configuration.ui.preferences[:my_home].add :home_layout_type
      configuration.ui.preferences[:messenger].add :skype_messenger
      configuration.ui.preferences[:messenger].add :yahoo_messenger
      configuration.ui.portal_contents[:information].add :information, :partial => "/part/my_contents_information/information"
      configuration.ui.profile_contents.add :friend_description, :type => :part
      configuration.ui.navigations.add :friend_navigation, :type => :part
    end

    # 携帯用のUI設定
    def initialize_default_ui_for_mobile
      configuration.ui.mobile_main_menus.add :search_index, :type => :inline,
        :inline => "▽<%= link_to('各種検索', search_index_users_path) %><br/>"
      configuration.ui.mobile_main_menus.add :my_message, :type => :inline,
        :inline => "▽<%= link_to('メッセージ', messages_path) %><br/>"
      configuration.ui.mobile_main_menus.add :my_friends, :type => :inline,
        :inline => "▽<%= link_to('トモダチ', friends_path) %><br/>"
      configuration.ui.mobile_main_menus.add :information, :type => :inline,
        :inline => "▽<%= link_to('お知らせ', informations_path) %><br/>"
      configuration.ui.mobile_main_menus.add :important_information, :type => :inline,
        :inline => "▽<%= link_to('重要なお知らせ', index_for_important_informations_path) %><br/>"
      configuration.ui.mobile_main_menus.add :invite, :type => :inline,
        :inline => "▽<%= link_to('トモダチ招待', new_invite_path) %><br/>"
      configuration.ui.mobile_profile_menus.add :send_message, :type => :inline,
        :inline => "▽<%= link_to('メッセージ送信', new_message_path(:individually => 1, :receiver_id => displayed_user.id)) %>"
      configuration.ui.mobile_profile_menus.add :friend_description_list, :type => :inline,
        :inline => "▽<%= link_to('紹介文', list_description_user_friends_path(:user_id => displayed_user.id)) %>"
      configuration.ui.mobile_search_links.add :user_search_link, :url => {:controller => :users, :action => :search_member_form}, :for => [:logged_in]
      configuration.ui.mobile_portal_menus.add :information, :type => :inline,
        :inline => "<%= link_to('お知らせ', informations_path) %>"
      configuration.ui.mobile_portal_menus.add :search_index, :type => :inline,
        :inline => "<%= link_to('各種検索', search_index_users_path) %>"
      configuration.ui.mobile_portal_menus.add :news_index, :type => :inline,
        :inline => "<%= link_to('新着情報', news_index_users_path) %>"
      configuration.ui.mobile_my_home_contents.add :new_message, :type => :part
    end
  end
end


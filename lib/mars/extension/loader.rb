# RadiantCMS の lib/radiant/extension_loader.rb を参考にしています．
module Mars
  class Extension::Loader
    include Singleton
    attr_accessor :initializer, :extensions

    def initialize
      self.extensions = []
    end

    # extension 内のロードパスに追加しなければならないディレクトリのパス一覧取得
    def extension_load_paths
      load_extension_roots.map{ |extension| load_paths_for(extension) }.flatten.
        select{|d| File.directory?(d) }
    end
    
    # extension のプラグインディレクトリ
    def plugin_paths
      load_extension_roots.map{|extension| "#{extension}/vendor/plugins" }.
        select{|d| File.directory?(d) }
    end

    # ロードパスに extension 内のディレクトリパスを追加
    def add_extension_paths
      extension_load_paths.reverse_each do |path|
        configuration.load_paths.unshift path
        $LOAD_PATH.unshift path
      end
    end

    # extension 内のルート設定用のファイル追加
    def add_routing_configuration_files
      extension_paths_for("config/routes.rb").each do |routes_path|
        ActionController::Routing::Routes.add_configuration_file(routes_path)
      end
    end

    def add_plugin_paths
      configuration.plugin_paths.concat plugin_paths
    end

    # extension 内のコントローラパスを追加
    def add_controller_paths
      configuration.controller_paths += controller_paths
    end

    def add_i18n_locale_paths
      configuration.i18n.load_path += i18n_locale_paths
    end

    def view_paths
      extension_paths_for("app/views")
    end
    
    def metal_paths
      extension_paths_for("app/metal")
    end

    def i18n_locale_paths
      load_extension_roots.map do |root|
        Dir[File.join(root, 'config', 'locales', '*.{rb,yml}')]
      end.flatten
    end

    def controller_paths
      extension_paths_for("app/controllers")
    end

    def stylesheet_paths
      extension_paths_for_with_extension_name("public/stylesheets")
    end
    
    def javascript_paths
      extension_paths_for_with_extension_name("public/javascripts")
    end
    
    def image_paths
      extension_paths_for_with_extension_name("public/images")
    end
    
    def theme_image_paths(theme)
      extension_paths_for_with_extension_name("themes/#{theme}/images")
    end

    def theme_stylesheet_paths(theme)
      extension_paths_for_with_extension_name("themes/#{theme}/stylesheets")
    end

    def theme_javascript_paths(theme)
      extension_paths_for_with_extension_name("themes/#{theme}/javascripts")
    end

    # 定義した extension のディレクトリの xxx_extension クラスをロード
    def load_extensions
      self.extensions = load_extension_roots.map do |root|
        begin
          extension_file = "#{File.basename(root).sub(/^\d+_/,'')}_extension"
          extension = extension_file.camelize.constantize
          extension.unloadable
          extension.instance.root = root
          extension
        rescue LoadError, NameError => e
          $stderr.puts "Could not load extension from file: #{extension_file}.\n#{e.inspect}"
          nil
        end
      end.compact
    end

    def activate_extensions
      # Reset the view paths after
      self.initializer.initialize_default_ui
      self.initializer.initialize_framework_views
      self.extensions.each(&:activate)
      self.extensions.each(&:after_activate)
    end

    def deactivate_extensions
      self.extensions.each(&:deactivate)
    end

    private

    def load_paths_for(dir)
      if File.directory?(dir)
        %w(lib app/models app/controllers app/metal app/helpers).collect do |p|
          path = "#{dir}/#{p}"
          path if File.directory?(path)
        end.compact << dir
      else
        []
      end
    end

    def load_extension_roots
      @load_extension_roots ||= configuration.extensions.empty? ? [] : select_extension_roots
    end

    def select_extension_roots
      all_roots = all_extension_roots.dup

      roots = configuration.extensions.map do |ext_name|
        if :all === ext_name
          :all
        else
          ext_path = all_roots.detect do |maybe_path|
            File.basename(maybe_path).sub(/^\d+_/, '') == ext_name.to_s
          end
          raise LoadError, "Cannot find the extension '#{ext_name}'!" if ext_path.nil?
          all_roots.delete(ext_path)
        end
      end

      if placeholder = roots.index(:all)
        # replace the :all symbol with any remaining paths
        roots[placeholder, 1] = all_roots
      end
      roots
    end

    # extension 内の指定したディレクトリパス
    def extension_paths_for(relative_path)
      load_extension_roots.map{|root| File.join(root, relative_path) }.
        select{ |d| File.exist?(d) }.reverse
    end

    # extension 内の指定したディレクトリパスに extension 名を付けたパス
    # 一覧を返す
    def extension_paths_for_with_extension_name(relative_path)
      load_extension_roots.
        map{|root| File.join(root, relative_path, File.basename(root).sub(/^\d+_/,'')) }.
        select{ |d| File.exist?(d) }.reverse
    end

    def all_extension_roots
      @all_extension_roots ||= configuration.extension_paths.map do |path|
        Dir[File.join(path, "*")].
          map{|f| File.expand_path(f) if File.directory?(f) }.compact.sort
      end.flatten
    end

    def configuration
      initializer.configuration
    end
  end
end

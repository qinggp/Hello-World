require 'singleton'

# 拡張機能基底クラス
# 
# 拡張機能ではこのクラスを継承します．
#
# activate を子クラスで定義すると拡張機能が活性化する際の処理が記述できます．
# 逆に deactivate は非活性化する際の処理を記述します．
# 
# RadiantCMS の extension 機能を参考にしました．
module Mars
  class Extension
    include Singleton
    attr_accessor :extension_name, :actived, :root

    # extension が動作中か？
    def actived?
      @actived
    end
    alias :active? :actived?

    # UI設定オブジェクト取得
    def ui
      UI.instance
    end

    # migration ファイル置き場へのパス
    def migrations_path
      File.join(self.root, 'db', 'migrate')
    end

    # migrator の取得
    def migrator
      unless @migrator
        extension = self
        @migrator = Class.new(Migrator){ self.extension = extension }
      end
      @migrator
    end

    # 他の拡張機能が有効になっているかチェック．
    # これを利用すれば以下のようなコードがかける．
    #
    # if MyExtension.extension_enabled?(:third_party)
    #   ThirdPartyExtension.extend(MyExtension::IntegrationPoints)
    # end
    def extension_enabled?(extension)
      begin
        extension = (extension.to_s.camelcase + 'Extension').constantize.instance
        # NOTE: テスト環境の場合はマイグレーションされていなくても true とする。
        # schema.rb をロードの際（テスト時）に拡張機能のバージョンが schema_migrations に追加されないため。
        # NOTE: プロダクション環境も同じく true とする。SQLが毎回発行されてしまうため。
        extension.actived? &&
          (!do_migration_check? || extension.migrator.new(:up, extension.migrations_path).pending_migrations.empty?)
      rescue NameError, ActiveRecord::ActiveRecordError => ex
        Rails.logger.debug{ "ERROR: #{ex.class} : #{ex.message}" }
        false
      end
    end

    # マイグレーションまでチェックするか？
    def do_migration_check?
      "development" == RAILS_ENV
    end

    class << self
      # extension 名を設定
      def inherited(subclass)
        super
        subclass.instance.extension_name = subclass.name.sub(/Extension$/, "")
      end

      # extension 起動
      def activate
        return if instance.actived?
        instance.activate if instance.respond_to? :activate
        ActionController::Routing::Routes.reload
        instance.actived = true
      end

      # すべてのactivate終了後に呼び出される
      def after_activate
        if instance.actived && instance.respond_to?(:after_activate)
          instance.after_activate
        end
      end

      # extension 停止
      def deactivate
        return unless instance.actived?
        instance.actived = false
        instance.deactivate if instance.respond_to? :deactivate
      end

      # class MyExtension < Mars::Extension
      #   extension_config do |config|
      #     config.gem 'gem_name'
      #     config.extension 'other-extension-name'
      #     config.after_initialize do
      #       run_something
      #     end
      #   end
      # end
      def extension_config(&block)
        yield Rails.configuration
      end
    end

  end
end

require File.dirname(__FILE__) + '/../../../../test_helper'

# 拡張機能Loaderテスト
class Mars::Extension::LoaderTest < ActiveSupport::TestCase
  def setup
    @instance = Mars::Extension::Loader.send(:new)
    @instance.initializer = Mars::Initializer.new(Mars::Configuration.new)
  end

  # 拡張機能用に通すロードパスのチェック
  test "extension_load_paths" do
    res = @instance.extension_load_paths
    expects = %w(
      /test/fixtures/extensions/01_test_basic
      /test/fixtures/extensions/01_test_basic/app/models
      /test/fixtures/extensions/01_test_basic/app/controllers
      /test/fixtures/extensions/01_test_basic/app/helpers
      /test/fixtures/extensions/01_test_basic/app/metal
      /test/fixtures/extensions/01_test_basic/lib
    ).map{|path| File.join(RAILS_ROOT, path)}

    assert_equal true, expects.all?{|path| res.include?(path) }

    expects.each{|path| res.delete(path) }
    assert_equal false, res.any?{|path| path.include?("01_test_basic")}
  end

  # 拡張機能用に通すプラグイン用パスのチェック
  test "plugin_paths" do
    assert_equal(true,
                 @instance.plugin_paths.any? do |path|
                   path == File.join(RAILS_ROOT, "test/fixtures/extensions/01_test_basic/vendor/plugins")
                 end)
                 
  end

  # 拡張機能をロードパスに追加
  test "add_extension_paths" do
    before_conf_load_paths_size = @instance.send(:configuration).load_paths.size
    before_load_paths_size = $LOAD_PATH.size

    @instance.add_extension_paths

    assert_equal true, @instance.send(:configuration).load_paths.size > before_conf_load_paths_size
    assert_equal true, $LOAD_PATH.size > before_load_paths_size
  end

  # 拡張機能内のプラグインをロードパスに追加
  test "add_plugin_paths" do
    before_plugin_load_paths_size = @instance.send(:configuration).plugin_paths.size

    @instance.add_plugin_paths

    assert_equal true, @instance.send(:configuration).plugin_paths.size > before_plugin_load_paths_size
  end

  # 拡張機能内のコントローラをロードパスに追加
  test "add_controller_paths" do
    before_controller_paths_size = @instance.send(:configuration).controller_paths.size

    @instance.add_controller_paths

    assert_equal true, @instance.send(:configuration).controller_paths.size > before_controller_paths_size
  end

  # 拡張機能内のI18nローカルディレクトリをロードパスに追加
  test "add_i18n_locale_paths" do
    before_i18n_load_paths_size = @instance.send(:configuration).i18n.load_path.size

    @instance.add_i18n_locale_paths

    assert_equal true, @instance.send(:configuration).i18n.load_path.size > before_i18n_load_paths_size
  end

  # 拡張機能用に通すView用パスのチェック
  test "view_paths" do
    expect = File.join(RAILS_ROOT, "test/fixtures/extensions/01_test_basic/app/views")
    assert_equal true, @instance.view_paths.any?{|path| path == expect}
  end

  # 拡張機能用に通すMetal用パスのチェック
  test "metal paths" do
    expect = File.join(RAILS_ROOT, "test/fixtures/extensions/01_test_basic/app/metal")
    assert_equal true, @instance.metal_paths.any?{|path| path == expect}
  end


  # 拡張機能用に通すMetal用パスのチェック
  test "i18n locale paths" do
    expect = File.join(RAILS_ROOT, "test/fixtures/extensions/01_test_basic/config/locales/ja.yml")
    assert_equal true, @instance.i18n_locale_paths.any?{|path| path == expect}
  end

  # 拡張機能用に通すコントローラ用パスのチェック
  test "controller paths" do
    expect = File.join(RAILS_ROOT, "test/fixtures/extensions/01_test_basic/app/controllers")
    assert_equal true, @instance.controller_paths.any?{|path| path == expect}
  end

  # 拡張機能で作成したスタイルシートディレクトリパス
  test "stylesheet_paths" do
    expect = File.join(RAILS_ROOT, "test/fixtures/extensions/01_test_basic/public/stylesheets/test_basic")
    assert_equal true, @instance.stylesheet_paths.any?{|path| path == expect}
  end

  # 拡張機能で作成した画像ディレクトリパス
  test "image_paths" do
    expect = File.join(RAILS_ROOT, "test/fixtures/extensions/01_test_basic/public/images/test_basic")
    assert_equal true, @instance.image_paths.any?{|path| path == expect}
  end

  # 拡張機能用に通すjavascriptディレクトリパス
  test "javascript_paths" do
    expect = File.join(RAILS_ROOT, "test/fixtures/extensions/01_test_basic/public/javascripts/test_basic")
    assert_equal true, @instance.javascript_paths.any?{|path| path == expect}
  end

  # 拡張機能のロード
  test "load extensions" do
    assert_equal true, @instance.load_extensions.include?(TestBasicExtension)
  end

  # 拡張機能の活性化
  test "activate extensions" do
    extensions = [TestBasicExtension]
    @instance.extensions = extensions
    TestBasicExtension.deactivate
    assert_equal false, TestBasicExtension.instance.actived?
    @instance.activate_extensions
    assert_equal true, TestBasicExtension.instance.actived?
  end

  # 拡張機能の非活性化
  test "deactivate extensions" do
    extensions = [TestBasicExtension]
    @instance.extensions = extensions
    TestBasicExtension.activate
    assert_equal true, TestBasicExtension.instance.actived?
    @instance.deactivate_extensions
    assert_equal false, TestBasicExtension.instance.actived?
  end
end

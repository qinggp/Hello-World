require File.dirname(__FILE__) + '/../../../test_helper'

# Mars初期化テスト
class Mars::InitializerTest < ActiveSupport::TestCase
  def setup
    @configuration = Mars::Configuration.new
    @initializer = Mars::Initializer.new(Mars::Configuration.new)
    @loader = Mars::Extension::Loader.instance
  end

  # 拡張機能名設定
  test "extension" do
    @configuration.extension("test_basic")
    assert_equal 'test_basic', *@configuration.extension_dependencies
  end

  # 依存関係にある拡張機能チェック
  test "check_extension_dependencies" do
    aborted = false
    stub(@configuration).abort{ aborted = true }
    @configuration.extensions = [TestBasicExtension]
    @configuration.extension('test_basic')
    assert_equal true, @configuration.check_extension_dependencies
    assert_equal false, aborted
  end

  # 依存関係にある拡張機能チェック（失敗）
  test "check_extension_dependencies fail" do
    aborted = false
    stub(@configuration).abort{ aborted = true }
    @configuration.extensions = [TestBasicExtension]
    @configuration.extension('not_exist')
    @configuration.check_extension_dependencies
    assert_equal true, aborted
  end

  # ロードパスの設定
  test "set_load_path" do
    mock(@loader).add_plugin_paths.never
    mock(@loader).add_extension_paths.never
    @initializer.set_load_path
  end

  # ルートの設定
  test "initialize_routing" do
    mock(@loader).add_controller_paths.once
    @initializer.send(:initialize_routing)
  end
  
  # 初期化後の設定
  test "after_initialize" do
    mock(@initializer.send(:extension_loader)).activate_extensions.once
    mock(@initializer.send(:configuration)).check_extension_dependencies.once
    @initializer.send(:after_initialize)
  end
  
  # Metalのロードパス確認
  test "load metal" do
    expects = ["#{RAILS_ROOT}/app/metal",
               "#{RAILS_ROOT}/test/fixtures/extensions/02_test_overriding/app/metal",
               "#{RAILS_ROOT}/test/fixtures/extensions/01_test_basic/app/metal"]
    expects.each do |ex|
      assert_equal true, Rails::Rack::Metal.metal_paths.any?{|path| path == ex}
    end
  end

  # 初期化後の設定
  #
  # 拡張期の依存関係チェックが呼ばれるか
  test "after_initialize with check dependent extensions" do
    @initializer.configuration.frameworks = []
    mock(@initializer.configuration).check_extension_dependencies.once
    @initializer.send(:after_initialize)
  end

  # extension 内の public ファイルに適切に symlink が貼られるか
  def test_set_extensions_public_symlink
    deletes = []
    symlinks = []
    stub(File).delete{|path| deletes << path }
    stub(File).symlink{|to, from| symlinks << [to, from] }

    @initializer.configuration
    @initializer.set_extensions_public_symlink

    assert_not_nil symlinks.any?{|d| d == "#{RAILS_ROOT}/public/javascripts/test_basic"}
    assert_not_nil symlinks.any?{|d| d == "#{RAILS_ROOT}/public/stylesheets/test_basic"}
    assert_not_nil symlinks.any?{|d| d == "#{RAILS_ROOT}/public/images/test_basic"}
  end
end

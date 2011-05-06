require File.dirname(__FILE__) + '/../../../test_helper'

# 拡張機能基底クラス
class ExtensionTest < ActiveSupport::TestCase

  # ui メソッドから Mars::UI のインスタンスが取得できる
  test "have ui" do
    assert_equal TestBasicExtension.instance.ui, Mars::UI.instance
  end

  # migrator メソッドから Mars::Migrator の子クラスが取得できる
  test "have migrator" do
    assert_equal TestBasicExtension.instance.migrator.superclass, Mars::Extension::Migrator
  end

  # Mars::Extension を継承すると子クラスに正しい拡張機能名が設定される
  test "set the extension_name in subclasses" do
    Kernel.module_eval { class ::SuperExtension < ::Mars::Extension; end }
    assert_equal ::SuperExtension.instance.extension_name, "Super"
  end

  # 拡張機能側で呼ぶ extension_config で渡される config クラスのチェック
  test "expose configuration object" do
    Kernel.module_eval { class ::SuperExtension < ::Mars::Extension; end }
    ::SuperExtension.extension_config do |config|
      assert_equal config, Rails.configuration
    end
  end

  # 拡張機能存在チェック
  # 
  # 存在しない拡張機能名を指定する
  test "extension enabled with not exist" do
    assert_equal false, TestBasicExtension.instance.extension_enabled?(:bogus)
  end

  # 拡張機能存在チェック
  # 
  # 存在する拡張機能名を指定する
  test "extension enabled with exist" do
    assert_equal true, TestBasicExtension.instance.extension_enabled?(:test_overriding)
  end

  # 拡張機能存在チェック
  #
  # 未実行の migration が残っている拡張機能を指定する
  test "extension enabled with not migrated" do
    assert_equal(false,
                 TestUpgradingExtension.instance.migrator.
                 new(:up, TestUpgradingExtension.instance.migrations_path).
                 pending_migrations.empty?)
    stub(TestBasicExtension.instance).do_migration_check?{ true }
    assert_equal false, TestBasicExtension.instance.extension_enabled?(:test_upgrading)
  end

  # 拡張機能存在チェック
  #
  # migration がすべて実行済みの拡張機能を指定する
  test "extension enabled with migrated" do
    ActiveRecord::Migration.suppress_messages do
      TestUpgradingExtension.instance.migrator.migrate
    end
    assert_equal true, TestBasicExtension.instance.extension_enabled?(:test_upgrading)
  end

  # 拡張機能アクティブ化
  #
  # 拡張機能がデアクティブな状態からアクティブにする
  test "become active" do
    TestBasicExtension.deactivate
    TestBasicExtension.activate
    assert_equal true, TestBasicExtension.instance.active?
  end

  # 拡張機能デアクティブ化
  #
  # 拡張機能がアクティブな状態からアクティブにする
  test "become deactivate" do
    TestBasicExtension.deactivate
    assert_equal false, TestBasicExtension.instance.active?
  end

  # 拡張機能プラグインロードチェック
  #
  # 拡張機能がアクティブな状態で拡張機能内のプラグインはロードされている
  test "loaded plugins at activated" do
    assert_not_nil defined?(Multiple)
    assert_not_nil defined?(NormalPlugin)
  end
end

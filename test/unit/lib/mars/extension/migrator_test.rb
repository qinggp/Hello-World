require File.dirname(__FILE__) + '/../../../../test_helper'

# 拡張機能マイグレータ
class Mars::Extension::MigratorTest < ActiveSupport::TestCase
  
  class Person < ActiveRecord::Base; end
  class Place < ActiveRecord::Base; end

  def setup
    ActiveRecord::Base.connection.delete("DELETE FROM schema_migrations WHERE version LIKE 'TsetBasic-%' OR version LIKE 'TestUpgrading-%'")
    ActiveRecord::Base.connection.delete("DELETE FROM extension_meta WHERE name = 'TsetUpgrading'")
  end

  # 拡張機能マイグレーション成功
  test "migrate success" do
    ActiveRecord::Migration.suppress_messages do
      TestBasicExtension.instance.migrator.migrate
    end
    assert_equal [200812131420,200812131421], TestBasicExtension.instance.migrator.get_all_versions
    assert_nothing_raised{ Person.find(:all) }
    assert_nothing_raised{ Place.find(:all) }
    ActiveRecord::Migration.suppress_messages do
      TestBasicExtension.instance.migrator.migrate(0)
    end
    assert_equal true, TestBasicExtension.instance.migrator.get_all_versions.empty?
  end

  # 拡張機能マイグレーション成功
  #
  # 拡張機能名を設定した場合
  test "migrate extensions with unusual names" do
    ActiveRecord::Migration.suppress_messages do
      TestSpecialCharactersExtension.instance.migrator.migrate
    end
    assert_equal [1], TestSpecialCharactersExtension.instance.migrator.get_all_versions
    assert_nothing_raised{ Person.find(:all) }
    ActiveRecord::Migration.suppress_messages do
      TestSpecialCharactersExtension.instance.migrator.migrate(0)
    end
    assert_equal true, TestSpecialCharactersExtension.instance.migrator.get_all_versions.empty?
  end

  # 拡張機能マイグレーション成功
  #
  # すでにマイグレーションが途中まで実施されている場合
  test "migrate with record existing extension migrations in the schema_migrations table" do
    ActiveRecord::Base.connection.insert("INSERT INTO extension_meta (name, schema_version) VALUES ('TestUpgrading', 2)")
    ActiveRecord::Migration.suppress_messages do
      TestUpgradingExtension.instance.migrator.migrate(3)
    end
    assert_equal [1,2,3], TestUpgradingExtension.instance.migrator.get_all_versions
    assert_equal(true,
                 ActiveRecord::Base.
                 connection.select_values("SELECT * FROM extension_meta WHERE name = 'TestUpgrading'").
                 empty?)
  end
end

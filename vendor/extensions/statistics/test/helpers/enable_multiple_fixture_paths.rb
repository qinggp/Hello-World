class Fixtures
  def self.create_fixtures(fixtures_directories, table_names, class_names = {})
    table_names = [table_names].flatten.map { |n| n.to_s }
    connection  = block_given? ? yield : ActiveRecord::Base.connection

    table_names_to_fetch = table_names.reject { |table_name| fixture_is_cached?(connection, table_name) }

    unless table_names_to_fetch.empty?
      ActiveRecord::Base.silence do
        connection.disable_referential_integrity do
          fixtures_map = {}

          fixtures = table_names_to_fetch.map do |table_name|
            # 複数のディレクトリからフィクスチャを選択できるように修正
            # しました．優先順位は配列に指定した順序順になります．
            fixtures_directory = 
              fixtures_directories.inject(fixtures_directories.last) do |acc, directory|
              fixture_file = File.join(directory, table_name.to_s)
                if File.file?("#{fixture_file}.yml") || File.file?("#{fixture_file}.csv")
                  break directory
                end
                acc
              end

            fixtures_map[table_name] = Fixtures.new(connection, File.split(table_name.to_s).last, class_names[table_name.to_sym],  File.join(fixtures_directory, table_name.to_s))
          end

          all_loaded_fixtures.update(fixtures_map)

          connection.transaction(:requires_new => true) do
            fixtures.reverse.each { |fixture| fixture.delete_existing_fixtures }
            fixtures.each { |fixture| fixture.insert_fixtures }

            # Cap primary key sequences to max(pk).
            if connection.respond_to?(:reset_pk_sequence!)
              table_names.each do |table_name|
                connection.reset_pk_sequence!(table_name)
              end
            end
          end

          cache_fixtures(connection, fixtures_map)
        end
      end
    end
    cached_fixtures(connection, table_names)
  end
end

class Test::Unit::TestCase
  superclass_delegating_accessor :fixture_paths

  class << self
    def fixtures(*table_names)
      if table_names.first == :all
        # fixtures(:all)を実行した場合に，指定された複数のディレクトリ
        # を探索するように修正しました．
        table_names = fixture_paths.map do |path|
          Dir["#{path}/*.yml"] + Dir["#{path}/*.csv"]
        end.flatten

        table_names.map! { |f| File.basename(f).split('.')[0..-2].join('.') }.uniq!
      else
        table_names = table_names.flatten.map { |n| n.to_s }
      end

      self.fixture_table_names |= table_names
      require_fixture_classes(table_names)
      setup_fixture_accessors(table_names)
    end
  end

  private
    def load_fixtures
      @loaded_fixtures = {}
      fixtures = Fixtures.create_fixtures(fixture_paths, fixture_table_names, fixture_class_names)
      unless fixtures.nil?
        if fixtures.instance_of?(Fixtures)
          @loaded_fixtures[fixtures.table_name] = fixtures
        else
          fixtures.each { |f| @loaded_fixtures[f.table_name] = f }
        end
      end
    end
end

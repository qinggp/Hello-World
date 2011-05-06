require 'rake/testtask'

namespace :db do
  namespace :migrate do
    desc "Run all Mars extension migrations"
    task :extensions => :environment do
      require 'mars/extension/migrator'
      Mars::Extension::Migrator.migrate_extensions
      Rake::Task['db:schema:dump'].invoke
    end
  end
  namespace :remigrate do
    desc "Migrate down and back up all Mars extension migrations"
    task :extensions => :environment do
      require 'highline/import'
      if agree("This task will destroy any data stored by extensions in the database. Are you sure you want to \ncontinue? [yn] ")
        require 'mars/extension/migrator'
        Object.subclasses_of(Mars::Extension).each {|ext| ext.instance.migrator.migrate(0) }
        Rake::Task['db:migrate:extensions'].invoke
        Rake::Task['db:schema:dump'].invoke
      end
    end
  end
end

namespace :test do
  desc "Runs tests on all available Mars extensions, pass EXT=extension_name to test a single extension"
  task :extensions => "db:test:prepare" do
    extension_roots = Object.subclasses_of(Mars::Extension).map(&:instance).map(&:root)
    if ENV["EXT"]
      extension_roots = extension_roots.select {|x| /\/(\d+_)?#{ENV["EXT"]}$/ === x }
      if extension_roots.empty?
        puts "Sorry, that extension is not installed."
      end
    end
    extension_roots.each do |directory|
      if File.directory?(File.join(directory, 'test'))
        chdir directory do
          if RUBY_PLATFORM =~ /win32/
            system "rake.cmd"
          else
            system "rake test"
          end
        end
      end
    end
  end
end

namespace :mars do
  namespace :extensions do
    desc "Runs update asset task for all extensions"
    task :update_all => :environment do
      extension_names = Mars::Extension::Loader.instance.extensions.map { |f| f.to_s.underscore.sub(/_extension$/, '') }
      extension_update_tasks = extension_names.map { |n| "mars:extensions:#{n}:update" }.select { |t| Rake::Task.task_defined?(t) }
      extension_update_tasks.each {|t| Rake::Task[t].invoke }
    end

    desc "update exntension fixtures"
    task :update_fixtures => :environment do
      new_files = []
      extensions = Object.subclasses_of(Mars::Extension).map(&:instance)

      extensions.each do |ex|
        fixtures_dir = File.join(ex.root, 'test', 'fixtures')
        if File.exist?(fixtures_dir)
          Dir.glob(File.join(fixtures_dir, '*.yml')).each do |fixture_file|
            copy_dir = File.join(Rails.root, 'test', 'fixtures', File.basename(fixture_file, '.*'))
            unless File.exist?(copy_dir)
              FileUtils.mkdir(copy_dir)
              new_files << copy_dir
            end
            FileUtils.cp(fixture_file, "#{File.join(copy_dir, ex.extension_name.downcase)}.yml")

            touch_file = copy_dir + ".yml"
            unless File.exist?(touch_file)
              FileUtils.touch touch_file
              new_files << touch_file
            end
          end
        end

        File.open(File.join(Rails.root, 'test', 'fixtures', '.tmp'), "w"){|f| f.print new_files.join(",") }
      end
    end

    desc "clean exntension fixtures"
    task :clean_fixtures => :environment do
      rm_r_files = File.read(File.join(Rails.root, 'test', 'fixtures', ".tmp")).split(",")
      rm_r_files.each{|f| FileUtils.rm_r f }
      FileUtils.rm File.join(Rails.root, 'test', 'fixtures', ".tmp")
    end
  end
end

# 拡張機能のカスタムタスクファイル群を読み込み
[RAILS_ROOT].uniq.each do |root|
  Dir[root + '/vendor/extensions/*/lib/tasks/*.rake'].sort.each { |ext| load ext }
end

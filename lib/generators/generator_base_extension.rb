require 'rails_generator'
module Mars
  module GeneratorBaseExtension
    def self.included(base)
      base.class_eval %{
        alias_method_chain :existing_migrations, :extensions
      }
    end

    # マイグレーションが重複していないかのチェックを拡張機能ディレクトリでも行う
    def existing_migrations_with_extensions(file_name)
      Dir.glob("#{destination_path(@migration_directory)}/[0-9]*_*.rb").grep(/[0-9]+_#{file_name}.rb$/)
    end

  end
end
Rails::Generator::Commands::Base.class_eval { include Mars::GeneratorBaseExtension }
class ExtensionGenerator < Rails::Generator::NamedBase
  default_options :with_test_unit => false
  
  attr_reader :extension_path, :extension_file_name
  
  def initialize(runtime_args, runtime_options = {})
    super
    @extension_file_name = "#{file_name}_extension"
    @extension_path = "vendor/extensions/#{file_name}"
  end
  
  def manifest
    record do |m|
      m.directory "#{extension_path}/config"
      m.directory "#{extension_path}/config/locales"
      m.directory "#{extension_path}/app/controllers"
      m.directory "#{extension_path}/app/helpers"
      m.directory "#{extension_path}/app/models"
      m.directory "#{extension_path}/app/views"
      m.directory "#{extension_path}/app/views/part"
      m.directory "#{extension_path}/db/migrate"
      m.directory "#{extension_path}/lib/tasks"
      m.directory "#{extension_path}/public/"
      m.directory "#{extension_path}/public/javascripts"
      m.directory "#{extension_path}/public/javascripts/#{file_name}"
      m.directory "#{extension_path}/public/stylesheets"
      m.directory "#{extension_path}/public/stylesheets/#{file_name}"
      m.directory "#{extension_path}/public/images"
      m.directory "#{extension_path}/public/images/#{file_name}"
      
      m.template 'README',              "#{extension_path}/README"
      m.template 'extension.rb',        "#{extension_path}/#{extension_file_name}.rb"
      m.template 'tasks.rake',          "#{extension_path}/lib/tasks/#{extension_file_name}_tasks.rake"
      m.template 'routes.rb',           "#{extension_path}/config/routes.rb"
      m.template 'ja.yml',              "#{extension_path}/config/locales/ja.yml"
      m.template 'part_helper.rb',      "#{extension_path}/app/helpers/#{file_name}_part_helper.rb"
      m.template 'stylesheet.css',      "#{extension_path}/public/stylesheets/#{file_name}/#{file_name}.css"
      m.template 'javascript.js',       "#{extension_path}/public/javascripts/#{file_name}/#{file_name}.js"

      if options[:with_rspec]
        m.directory "#{extension_path}/spec/controllers"
        m.directory "#{extension_path}/spec/models"        
        m.directory "#{extension_path}/spec/views"
        m.directory "#{extension_path}/spec/helpers"

        m.template 'RSpecRakefile',       "#{extension_path}/Rakefile"
        m.template 'spec_helper.rb',      "#{extension_path}/spec/spec_helper.rb"
        m.file     'spec.opts',           "#{extension_path}/spec/spec.opts"
      else
        m.directory "#{extension_path}/test/fixtures"
        m.directory "#{extension_path}/test/functional"
        m.directory "#{extension_path}/test/unit"
        m.directory "#{extension_path}/test/helpers"

        m.template 'Rakefile',            "#{extension_path}/Rakefile"
        m.template 'test_helper.rb',      "#{extension_path}/test/test_helper.rb"
        m.template 'functional_test.rb',  "#{extension_path}/test/functional/#{extension_file_name}_test.rb"
        m.template 'enable_multiple_fixture_paths.rb',  "#{extension_path}/test/helpers/enable_multiple_fixture_paths.rb"
      end
    end
  end
  
  def class_name
    super.classify.gsub(' ', '') + 'Extension'
  end
  
  def extension_name
    class_name.sub(/Extension$/, '')
  end
  
  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--with-rspec", 
           "Use RSpec for this extension instead of Test::Unit") { |v| options[:with_rspec] = v }
  end
end

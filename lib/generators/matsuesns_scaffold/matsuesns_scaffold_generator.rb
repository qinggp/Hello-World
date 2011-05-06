class MatsuesnsScaffoldGenerator < ScaffoldGenerator
  default_options :skip_model => false, :extension => false

  attr_reader :singular_name_with_nesting, :plural_name_with_nesting

  def manifest
    manifest = record do |m|
      # Check for class naming collisions.
      m.class_collisions(controller_class_path, "#{controller_class_name}Controller", "#{controller_class_name}Helper")
      m.class_collisions(class_path, "#{class_name}")
      generate(m)
    end

    action = File.basename($0) # grok the action from './script/generate' or whatever
    case action
    when "generate"
      # write message
      # puts <<-MESSAGES
      # MESSAGES
    end

    return manifest
  end

  def generate(m)
    # Controller, helper, views, test and stylesheets directories.
    m.directory(File.join('app/controllers', controller_class_path))
    m.directory(File.join('app/helpers', controller_class_path))
    m.directory(File.join('app/views', controller_class_path, controller_file_name))
    m.directory(File.join('test/functional', controller_class_path))
    m.directory(File.join('public/javascripts', controller_class_path))

    for action in scaffold_views
      m.template(
                 "view_#{action}.html.erb",
                 File.join('app/views', controller_class_path, controller_file_name, "#{action}.html.erb")
                 )
    end

    m.template(
               'controller.rb', File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")
               )
    extension_name = options[:extension_name].to_s
    m.template(
               'controller.css', File.join('public/stylesheets', extension_name, controller_class_path, "#{controller_file_name}.css")
               )
    m.template(
               'controller.js', File.join('public/javascripts', extension_name, controller_class_path, "#{controller_file_name}.js")
               )

    m.template('functional_test.rb', File.join('test/functional', controller_class_path, "#{controller_file_name}_controller_test.rb"))
    m.template('helper.rb',          File.join('app/helpers',     controller_class_path, "#{controller_file_name}_helper.rb"))

    unless options[:skip_model]
      m.dependency 'model', [singular_name] + @args, :collision => :skip
    end

    m.route_resources controller_file_name
  end
  
  protected

  def banner
    "Usage: #{$0} matsuesns_scaffold ModelName [field:type, field:type]"
  end

  def add_options!(opt)
    super
    opt.on("--skip-model", "Don't generate a model file") do |v|
      options[:skip_model] = v
    end
    opt.on("--extension VAL", "matsuesns extension generate") do |v|
      options[:extension] = true
      options[:destination] = File.join(RAILS_ROOT, "vendor/extensions", v)
      options[:extension_name] = v
    end
  end

  def scaffold_views
    %w[index show confirm form _complete_back_link _init
       _confirm _confirm_mobile _form _form_mobile confirm_before_destroy_mobile ]
  end

  def controller_class_nesting_with_colon
    controller_class_nesting.empty? ? nil : "#{controller_class_nesting}::"
  end

  def class_nesting_with_slash
    class_nesting.empty? ? nil : 
      class_nesting.split('::').map{|i| "#{i.downcase}/"}
  end

  def record_name_or_array
    array = class_nesting.split('::').map{|i| %Q|"#{i.downcase}"|}
    if array.empty?
      "@#{singular_name}"
    else
      array.push("@#{singular_name}")
      "[#{array.join(', ')}]"
    end
  end

  private

  def assign_names!(name)
    @name = name
    base_name, @class_path, @file_path, @class_nesting, @class_nesting_depth = extract_modules(@name)
    @class_name_without_nesting, @singular_name, @plural_name = inflect_names(base_name)
    @table_name = (!defined?(ActiveRecord::Base) || ActiveRecord::Base.pluralize_table_names) ? plural_name : singular_name
    @table_name.gsub! '/', '_'
    @class_name = @class_name_without_nesting
    if class_nesting.empty?
      @singular_name_with_nesting = @singular_name
      @plural_name_with_nesting = @plural_name
    else
      @singular_name_with_nesting = @class_nesting.underscore << "_" << @singular_name
      @plural_name_with_nesting = @class_nesting.underscore << "_" << @plural_name
    end
  end
end

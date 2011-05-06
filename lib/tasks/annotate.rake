namespace :mars do
  desc "Add schema information (as comments) to model files for mars"
  task :annotate_models do
    require "vendor/plugins/annotate_models/lib/annotate_models.rb"
    require "vendor/plugins/mars_bugfix/lib/annotate_models_fix_add_class_summary"
    AnnotateModels.do_annotations

    Dir.glob("#{Rails.root}/vendor/extensions/*") do |dir|
      MODEL_DIR = File.join(dir, "app/models")
      FIXTURE_DIR = File.join(dir, "test/fixtures")
      if [dir, MODEL_DIR, FIXTURE_DIR].all?{|d| File.directory?(d) }
        AnnotateModels.do_annotations
      end
    end
  end
end

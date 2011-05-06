require 'rake/testtask'

namespace :mars do
  namespace :themes do
    desc "Mars themes(and extension themes) rename."
    task :rename => :environment do
      to = ENV["TO"]
      from = ENV["FROM"]
      Rake::Task["themes:cache:remove"].invoke
      extensions = Object.subclasses_of(Mars::Extension).map(&:instance)
      extensions.each do |ex|
        if File.exist?(File.join(ex.root, "themes", from))
          FileUtils.mv(File.join(ex.root, "themes", from),
                       File.join(ex.root, "themes", to))
        end
      end
      if File.exist?(File.join(Rails.root, "themes", from))
        FileUtils.mv(File.join(Rails.root, "themes", from),
                     File.join(Rails.root, "themes", to))
      end
      Rake::Task["themes:cache:create"].invoke
    end
  end
end

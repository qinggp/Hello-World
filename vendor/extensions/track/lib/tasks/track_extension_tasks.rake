namespace :mars do
  namespace :extensions do
    namespace :track do
      
      desc "Runs the migration of the Track extension"
      task :migrate => :environment do
        require 'mars/extension/migrator'
        if ENV["VERSION"]
          TrackExtension.instance.migrator.migrate(ENV["VERSION"].to_i)
        else
          TrackExtension.instance.migrator.migrate
        end
      end

      desc "Copies public assets of the Track to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from TrackExtension"
        Dir[TrackExtension.instance.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(TrackExtension.instance.root, '')
          directory = File.dirname(path)
          mkdir_p RAILS_ROOT + directory, :verbose => false
          cp file, RAILS_ROOT + path, :verbose => false
        end
      end  
    end
  end
end

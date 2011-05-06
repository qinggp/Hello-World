namespace :mars do
  namespace :extensions do
    namespace :ranking do
      
      desc "Runs the migration of the Ranking extension"
      task :migrate => :environment do
        require 'mars/extension/migrator'
        if ENV["VERSION"]
          RankingExtension.instance.migrator.migrate(ENV["VERSION"].to_i)
        else
          RankingExtension.instance.migrator.migrate
        end
      end

      desc "Copies public assets of the Ranking to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from RankingExtension"
        Dir[RankingExtension.instance.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(RankingExtension.instance.root, '')
          directory = File.dirname(path)
          mkdir_p RAILS_ROOT + directory, :verbose => false
          cp file, RAILS_ROOT + path, :verbose => false
        end
      end  
    end
  end
end

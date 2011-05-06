namespace :mars do
  namespace :extensions do
    namespace :community do
      
      desc "Runs the migration of the Community extension"
      task :migrate => :environment do
        require 'mars/extension/migrator'
        if ENV["VERSION"]
          CommunityExtension.instance.migrator.migrate(ENV["VERSION"].to_i)
        else
          CommunityExtension.instance.migrator.migrate
        end
      end

      desc "Copies public assets of the Community to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from CommunityExtension"
        Dir[CommunityExtension.instance.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(CommunityExtension.instance.root, '')
          directory = File.dirname(path)
          mkdir_p RAILS_ROOT + directory, :verbose => false
          cp file, RAILS_ROOT + path, :verbose => false
        end
      end
    end
  end
end

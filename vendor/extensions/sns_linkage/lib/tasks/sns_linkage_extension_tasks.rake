namespace :mars do
  namespace :extensions do
    namespace :sns_linkage do
      
      desc "Runs the migration of the SnsLinkage extension"
      task :migrate => :environment do
        require 'mars/extension/migrator'
        if ENV["VERSION"]
          SnsLinkageExtension.instance.migrator.migrate(ENV["VERSION"].to_i)
        else
          SnsLinkageExtension.instance.migrator.migrate
        end
      end

      desc "Copies public assets of the SnsLinkage to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from SnsLinkageExtension"
        Dir[SnsLinkageExtension.instance.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(SnsLinkageExtension.instance.root, '')
          directory = File.dirname(path)
          mkdir_p RAILS_ROOT + directory, :verbose => false
          cp file, RAILS_ROOT + path, :verbose => false
        end
      end  
    end
  end
end

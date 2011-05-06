namespace :mars do
  namespace :extensions do
    namespace :<%= file_name %> do
      
      desc "Runs the migration of the <%= extension_name %> extension"
      task :migrate => :environment do
        require 'mars/extension/migrator'
        if ENV["VERSION"]
          <%= class_name %>.instance.migrator.migrate(ENV["VERSION"].to_i)
        else
          <%= class_name %>.instance.migrator.migrate
        end
      end

      desc "Copies public assets of the <%= extension_name %> to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from <%= class_name %>"
        Dir[<%= class_name %>.instance.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(<%= class_name %>.instance.root, '')
          directory = File.dirname(path)
          mkdir_p RAILS_ROOT + directory, :verbose => false
          cp file, RAILS_ROOT + path, :verbose => false
        end
      end  
    end
  end
end

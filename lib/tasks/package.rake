require 'fileutils'

app = "mars"
rails_root = File.join(File.dirname(__FILE__), '../..')
repository = "https://list.priv.netlab.jp/svn/matsuesns/src"
temp = "/tmp"
tempdir = File.join(temp, app)

plugin = "/vendor/plugins"
rm_plugins = %w()
plugindir = File.join(tempdir, plugin)

def env(env, options = {:safe => true})
  env = env.to_s.upcase
  if ENV[env].blank? && options[:safe]
    raise "No #{env} value given." 
  end

  return ENV[env]
end

def cleanup_tempdir(tempdir)
  if File.exist?(tempdir)
    FileUtils.rm_rf(tempdir) 
  end
end

namespace :mars do
  namespace :dist do
    desc "tag"
    task :tag => ['environment'] do
      cleanup_tempdir(tempdir)
      Rake::Task[:test].invoke
      revision = env(:revision, :safe => false) ? "-r #{env(:revision)}" : ""

      verbose(:verbose) do
        sh %Q|svn cp #{revision} -q -m "copy trunk to tags" #{repository}/trunk #{repository}/tags/#{env(:version)}|
        sh %Q|svn export -q #{repository}/tags/#{env(:version)} #{tempdir}|
        rm_plugins.each do |pl|
          sh %Q|cd #{temp} && rm -rf #{File.join(plugindir, pl)}|
        end
        sh %Q|cd #{temp} && zip -r #{env(:version)} #{app}|
      end
    end

    desc "untag"
    task :untag do
      cleanup_tempdir(tempdir)
      verbose(:verbose) do
        sh %Q|svn remove -q -m "remove wrong tag" #{repository}/tags/#{env(:version)}|
      end
    end

    desc "reset"
    task :reset => ["dist:untag", "dist:tag"]

    desc "clean"
    task :clean do
      cleanup_tempdir(tempdir)
    end
  end
end  

require 'singleton'
require 'yaml'

class Mars::Movie::ResourceLoader
  include Singleton

  # 設定ファイルパス
  RESOURCE_FILE_PATH = File.join(File.dirname(__FILE__),
                                 '../../../', 'config', 'resources.yml')

  def self.[](key)
    self.instance[key]
  end

  def [](key)
    load
    @resouces[key]
  end

  # 設定ファイルをロードします
  def load
    @resouces ||= YAML.load_file(RESOURCE_FILE_PATH)
  end
end

namespace :file_column do
  # file_columnで各モデルがファイルを格納しているするディレクトリ全て削除
  desc "delete all sub directories on file_column model"
  task :delete => :environment do
    FileUtils.rm_r Dir.glob(FileColumn::ClassMethods::DEFAULT_OPTIONS[:root_path] + "/*/image/[0-9]*")
  end
end


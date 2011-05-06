# NOTE: rake db:seed の場合のみの拡張
class ActiveRecord::Base
  # 指定された :id があれば update する。なければ create。
  def self.create_or_update(options = {})
    options = options.with_indifferent_access
    id = options.delete("id")
    record = find_by_id(id) || new
    record.id = id
    record.attributes = options
    record.save!

    record
  rescue ActiveRecord::ActiveRecordError => ex
    puts "ERROR: #{ex.class} : #{ex.message}"
    Rails.logger.error "ERROR: #{ex.class} : #{ex.message}"
    raise ex
  end
end

# DBマスターデータロード
require 'active_record/fixtures'
require 'action_controller/test_process'

ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
unless ENV["TEST_DATE_LOADING"]
  ActiveRecord::Base.transaction do
    (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(RAILS_ROOT, 'db', 'master_fixtures', '*.{yml,csv}'))).each do |fixture_file|
      tname = File.basename(fixture_file, '.*')
      table = tname.singularize.camelize.constantize
      records = YAML.load(ERB.new(IO.read(fixture_file)).result)
      records.each do |key, record|
        table.create_or_update(record)
      end
    end
  end
end

FIXTURES_PATH = File.join(RAILS_ROOT, "db/master_fixtures")
FILES_PATH = File.join(FIXTURES_PATH, "files")

# デフォルト顔写真アップロード
PreparedFacePhoto.create_or_update(:image => ActionController::TestUploadedFile.new(File.join(FILES_PATH, "10_male.jpeg"), "image/jpeg"),
                         :name => "10代（男）", :position => 1, :id => 1)
PreparedFacePhoto.create_or_update(:image => ActionController::TestUploadedFile.new(File.join(FILES_PATH, "10_female.jpeg"), "image/jpeg"),
                         :name => "10代（女）", :position => 2, :id => 2)
PreparedFacePhoto.create_or_update(:image => ActionController::TestUploadedFile.new(File.join(FILES_PATH, "20_male.jpeg"), "image/jpeg"),
                         :name => "20代（男）", :position => 3, :id => 3)
PreparedFacePhoto.create_or_update(:image => ActionController::TestUploadedFile.new(File.join(FILES_PATH, "20_female.jpeg"), "image/jpeg"),
                         :name => "20代（女）", :position => 4, :id => 4)
PreparedFacePhoto.create_or_update(:image => ActionController::TestUploadedFile.new(File.join(FILES_PATH, "30_male.jpeg"), "image/jpeg"),
                         :name => "30代（男）", :position => 5, :id => 5)
PreparedFacePhoto.create_or_update(:image => ActionController::TestUploadedFile.new(File.join(FILES_PATH, "30_female.jpeg"), "image/jpeg"),
                         :name => "30代（女）", :position => 6, :id => 6)
PreparedFacePhoto.create_or_update(:image => ActionController::TestUploadedFile.new(File.join(FILES_PATH, "40_50_male.jpeg"), "image/jpeg"),
                         :name => "40-50代（男）", :position => 7, :id => 7)
PreparedFacePhoto.create_or_update(:image => ActionController::TestUploadedFile.new(File.join(FILES_PATH, "40_50_female.jpeg"), "image/jpeg"),
                         :name => "40-50代（女）", :position => 8, :id => 8)
PreparedFacePhoto.create_or_update(:image => ActionController::TestUploadedFile.new(File.join(FILES_PATH, "60_male.jpeg"), "image/jpeg"),
                         :name => "老齢（男）", :position => 9, :id => 9)
PreparedFacePhoto.create_or_update(:image => ActionController::TestUploadedFile.new(File.join(FILES_PATH, "60_female.jpeg"), "image/jpeg"),
                         :name => "老齢（女）", :position => 10, :id => 10)

# db/master_fixtures以下にあるファイルをマスターとしてロードする
Dir.glob(File.join(FIXTURES_PATH, '*.{yml,csv}')).each do |fixture_file|
  Fixtures.create_fixtures(FIXTURES_PATH, File.basename(fixture_file, '.*'))
end


namespace :mars do

  namespace :db do
    desc "Initialize dabatbase"
    task :init => ['db:drop', 'db:create', 'db:migrate', 'db:migrate:extensions', 'db:schema:dump', 'db:seed'] do
      puts "If you want to JpAddress. You should run 'rake mars:db:jpaddress:load'"
    end

    namespace :jpaddress do
      # 郵便番号データインポート
      #
      # ==== 郵便番号データ更新方法
      #
      #   1. http://www.post.japanpost.jp/zipcode/download.html から最新のデータを取得する
      #   2. UTF-8に変換し、./master_fixtures/files/ken_all_utf8.csv を置き換え
      #   3. rake mars:db:jpaddress:load を行う。
      desc "Jpaddress data load, You can set CSV_FILE='csv_file.path'"
      task :load => :environment do
        FILES_PATH = File.join(RAILS_ROOT, "db/master_fixtures/files")
        csv_file = ENV["CSV_FILE"] || File.join(FILES_PATH, "ken_all_utf8.csv")

        puts "=== JpAddress Import Start ==="
        puts "Reading " + csv_file
        id = 1
        JpAddress.delete_all
        FasterCSV.foreach(csv_file) do |data|
          JpAddress.create(:id => id,
                           :zipcode => data[2],
                           :prefecture_id => data[0][0..1].strip,
                           :city => data[7].toutf8,
                           :town => data[8].toutf8.gsub(/^[０-９].*$|（.*$/u,""))
          id += 1
        end
      end
    end

    namespace :spamaddress do
      # スパムの送信元IPアドレスデータインポート
      #
      # === スパムIPアドレスデータ更新方法
      #
      # 1. http://www.stopforumspam.com/downloads/bannedips.zipから最新のデータを取得する
      # 2. 解凍したCSVを、./master_fixtures/files/bannedips.csvに配置する
      # 3. rake mars:db:spamaddress:load を行う
      desc "spamaddress data load, You can set CSV_FILE='csv_file.path'"
      task :load => :environment do
        FILES_PATH = File.join(RAILS_ROOT, "db/master_fixtures/files")
        csv_file = ENV["CSV_FILE"] || File.join(FILES_PATH, "bannedips.csv")

        puts "=== SpamIpAddress Import Start ==="
        puts "Reading " + csv_file

        SpamIpAddress.delete_all
        SpamIpAddress.transaction do
          File.read(csv_file).split(",").each do |address|
            ActiveRecord::Base.connection.execute "INSERT INTO spam_ip_addresses (ip_address) VALUES ('#{address}')"
          end
        end
      end
    end
  end

  namespace :test_data do
    desc "load integration test data"
    task :load => ['db:schema:dump', 'db:schema:load'] do
      ENV["TEST_DATE_LOADING"] = "true"
      Rake::Task["mars:extensions:update_fixtures"].invoke
      begin
        Rake::Task["db:fixtures:load"].invoke
      ensure
        Rake::Task["mars:extensions:clean_fixtures"].invoke
        Rake::Task["db:seed"].invoke
      end
    end
  end
end

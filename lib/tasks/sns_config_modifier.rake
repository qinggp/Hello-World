# sns_configsテーブルを実際の運用にふさわしい値に書き換える

namespace :mars do
  namespace :db do
    # sns_configsのデータを変更する
    desc "modify sns_configs record data"

    task :sns_configs_modifier => [:environment] do
      sns_config = SnsConfig.master_record
      unless sns_config
        puts "sns_configs table is not exists."
        puts "this task shall be executed after 'rake mars:test_data:load' etc."
        exit
      end

      # NOTE:以下の内容は、実機に合わせて適宜変えてください
      sns_config.title = "mars（テスト）"
      sns_config.outline = "テスト中となっております"
      sns_config.admin_mail_address = "test@example.com"
      sns_config.g_map_api_key = "ABQIAAAA-86td2I_y2l55xwIDGSTChQfYyxBpgFMXbsdWzVkpJ1g_011WxRlHQ6vDZuJMBhL5L8vgvwB97uMJQ"
      sns_config.entry_type = SnsConfig::ENTRY_TYPES[:free_registration]

      unless sns_config.save
        puts "fail to save sns_configs.\nplease look at itself, and run again."
      end
    end
  end
end


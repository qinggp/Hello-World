class CreateSnsConfigs < ActiveRecord::Migration
  def self.up
    create_table :sns_configs do |t|
      t.column :title,                   :string
      t.column :outline,                 :string
      t.column :entry_type,              :boolean
      t.column :invite_type,             :boolean
      t.column :approval_type,           :integer
      t.column :login_display_type,      :boolean
      t.column :admin_mail_address,      :string
      t.column :g_map_api_key,           :string
      t.column :g_map_longitude,         :float
      t.column :g_map_latitude,          :float
      t.column :g_map_zoom,              :integer
      t.column :ranking_display_flg,     :boolean
      t.column :relation_flg,            :boolean
      t.column :blog_default_open_range, :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :sns_configs
  end
end
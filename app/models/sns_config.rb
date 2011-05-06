# == Schema Information
# Schema version: 20100227074439
#
# Table name: sns_configs
#
#  id                      :integer         not null, primary key
#  title                   :string(255)
#  outline                 :string(255)
#  entry_type              :boolean
#  invite_type             :boolean
#  approval_type           :integer
#  login_display_type      :boolean
#  admin_mail_address      :string(255)
#  g_map_api_key           :string(255)
#  g_map_longitude         :float
#  g_map_latitude          :float
#  g_map_zoom              :integer
#  relation_flg            :boolean
#  created_at              :datetime
#  updated_at              :datetime
#  sns_theme_id            :integer
#  ranking_display_flg     :boolean         default(TRUE)
#  blog_default_open_range :integer
#

class SnsConfig < ActiveRecord::Base
  belongs_to "sns_theme"

  enum_column :entry_type, :invitation => false, :free_registration => true
  enum_column :invite_type, :invite => false, :no_invite => true
  enum_column :approval_type, :no_approval, :approved_by_administrator
  enum_column :login_display_type, :form_type => false, :portal_type => true
  enum_column :relation_flg, :disable => false, :enable => true
  enum_column :theme, :default => "matsuesns"

  validates_presence_of :title,
                        :outline,
                        :admin_mail_address,
                        :approval_type
  validates_length_of :outline,:title,:admin_mail_address, :within => 1..100
  validates_inclusion_of :entry_type, :in => ENTRY_TYPES.values
  validates_inclusion_of :invite_type, :in => INVITE_TYPES.values
  validates_inclusion_of :approval_type, :in => APPROVAL_TYPES.values
  validates_inclusion_of :login_display_type, :in => LOGIN_DISPLAY_TYPES.values
  validates_inclusion_of :relation_flg, :in => RELATION_FLGS.values

  # マスターデータからデータを取得するクラスメソッドを定義
  if self.table_exists?
    self.column_names.each do |name|
      class_eval(<<-METHOD)
      def self.#{name}
          return master_record.#{name}
      end
      METHOD
    end
  end

  def self.master_record
    return self.first if self.table_exists?
  end
end

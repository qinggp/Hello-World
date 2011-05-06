class AddProfileColumnsToUser < ActiveRecord::Migration
  def self.up
    # 本名
    add_column :users, :last_real_name, :string
    add_column :users, :first_real_name, :string
    add_column :users, :real_name_visibility, :integer

    # 現住所
    add_column :users, :now_prefecture_id, :integer
    add_column :users, :now_zipcode, :string
    add_column :users, :now_city, :string
    add_column :users, :now_street, :text
    add_column :users, :now_address_visibility, :integer

    # 顔写真
    add_column :users, :face_photo_id, :integer
    add_column :users, :face_photo_type, :string

    # 性別
    add_column :users, :gender, :integer

    # 出身県
    add_column :users, :home_prefecture_id, :integer

    # 血液型
    add_column :users, :blood_type, :integer

    # 電話番号
    add_column :users, :phone_number, :string

    # 趣味
    add_column :users, :hobby_id, :integer

    # 職業
    add_column :users, :job_id, :integer
    add_column :users, :job_visibility, :integer

    # 所属
    add_column :users, :affiliation, :string
    add_column :users, :affiliation_visibility, :integer

    # 一言メッセージ
    add_column :users, :message, :text

    # 自己紹介
    add_column :users, :detail, :text
  end

  def self.down
    remove_column :users, :affiliation
    remove_column :users, :job_id
    remove_column :users, :hobby_id
    remove_column :users, :phone_number
    remove_column :users, :now_street
    remove_column :users, :now_city
    remove_column :users, :now_zipcode
    remove_column :users, :blood_type
    remove_column :users, :home_prefecture_id
    remove_column :users, :gender
    remove_column :users, :now_prefecture_id
    remove_column :users, :detail
    remove_column :users, :message
    remove_column :users, :first_real_name
    remove_column :users, :last_real_name

    remove_column :users, :real_name_visibility
    remove_column :users, :face_photo_id
    remove_column :users, :now_address_visibility
    remove_column :users, :job_visibility
    remove_column :users, :affiliation_visibility
    remove_column :users, :face_photo_type
  end
end

# == Schema Information
# Schema version: 20100227074439
#
# Table name: prepared_face_photos
#
#  id       :integer         not null, primary key
#  name     :string(255)
#  image    :string(255)
#  position :integer
#

# デフォルト顔写真のDBマスターデータ
class PreparedFacePhoto < ActiveRecord::Base
  file_column :image,
              :magick => {
                :versions => {
                  :thumb => "40x40",
                  :medium => "120x120"},
              :image_required => false
  }

  attr_accessor :_delete

  # Viewに渡すセレクトボックスのオプション
  def self.select_options
    self.find(:all, :select => "id,name",:order => "position ASC").map{|r| [r.name, r.id]}
  end

  # 顔写真はデフォルトのものか？
  def prepared?
    true
  end

  # Viewに渡すfields_for名
  def fields_for_name
    "prepared_face_photo_attributes"
  end

  # 削除フラグsetter
  def _delete=(value)
    @_delete = value.blank? ? nil : value
  end
end

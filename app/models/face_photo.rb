# == Schema Information
# Schema version: 20100227074439
#
# Table name: face_photos
#
#  id         :integer         not null, primary key
#  image      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class FacePhoto < ActiveRecord::Base
  file_column :image,
              :magick => {
                :versions => {
                  :thumb => "40x40",
                  :medium => "120x120"},
              :image_required => false
  }

  validates_file_format_of :image, :in => %w(jpg jpeg png)
  validates_filesize_of :image, :in => 0..300.kilobytes
  attr_accessor :_delete

  # 顔写真はデフォルトのものか？
  def prepared?
    false
  end

  # Viewに渡すfields_for名
  def fields_for_name
    "face_photo_attributes"
  end

  # 削除フラグsetter
  def _delete=(value)
    @_delete = value.blank? ? nil : value
  end
end

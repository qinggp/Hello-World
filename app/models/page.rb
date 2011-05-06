# == Schema Information
# Schema version: 20100227074439
#
# Table name: pages
#
#  id         :integer         not null, primary key
#  page_id    :string(255)
#  title      :text
#  body       :text
#  created_at :datetime
#  updated_at :datetime
#

class Page < ActiveRecord::Base

  @@default_index_order = "pages.page_id ASC"
  cattr_reader :default_index_order

  validates_presence_of :title, :body, :page_id
  validates_uniqueness_of :page_id

  # アップロード可能なファイル形式
  FILE_EXTENSION = ["jpg", "jpeg", "gif", "png", "bmp"]
  
  # アップロード可能なファイルサイズ
  FILE_MAX_SIZE = 300.kilobytes
  FILE_MIN_SIZE = 1.bytes

  def self.validate_upload_image(image)
    extension_error = true
    FILE_EXTENSION.each do |extension|
      if image.content_type == "image/#{extension}"
        extension_error = false
        break
      end
    end
    return "アップロード可能なファイル形式は#{FILE_EXTENSION.join(", ")}です" if extension_error
    if image.size > FILE_MAX_SIZE
      return "アップロード可能なファイルのサイズは#{FILE_MAX_SIZE}以下です"
    elsif image.size < FILE_MIN_SIZE
      return "アップロード可能なファイルのサイズは#{FILE_MIN_SIZE}以上です。"
    end
    return nil
  end


end

# == Schema Information
# Schema version: 20100227074439
#
# Table name: banners
#
#  id          :integer         not null, primary key
#  image       :string(255)
#  link_url    :string(255)
#  comment     :text
#  expire_date :datetime
#  click_count :integer         default(0)
#  created_at  :datetime
#  updated_at  :datetime
#

class Banner < ActiveRecord::Base

  #ファイルのアップロード制限サイズ
  FILE_SIZE = 1..1024000.bytes

  # 画像の広告表示用のサイズ
  MEDIUM = '300x60'

  validates_presence_of :comment
  validates_length_of :comment, :maximum => 254, :too_long => 'は254文字以内にしてください。'

  validates_format_of :link_url, :with => URI.regexp(['http', 'https', 'ftp']), :if => :link_url_not_blank?
  validates_file_format_of :image, :in => ["gif", "swf"]
  validates_filesize_of :image, :in => FILE_SIZE,
                        :too_large_message => "のサイズが大きすぎます。",
                        :too_small_message => "のサイズが小さすぎます。"


  file_column :image, :magick => {
                :versions => {:medium => MEDIUM },
                :image_required => false
              },
                :fix_file_extentions => false

 

  def validate
    if image.blank?
      errors.add(:image,"がありません")
    end
  end

  def link_url_not_blank?
    return false if self.link_url.blank?
    true
  end


end

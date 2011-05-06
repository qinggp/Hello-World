require 'RMagick'
require 'rqrcode'

# RQRCodeから画像データを出力
module Mars::QRCodeRMagick
  def self.included(klass)
    klass.send(:include, InstanceMethods)
  end

  module InstanceMethods
    # QRコードのバイナリ出力
    def to_qr_binary(elm_size = 4, image_format = 'png')
      image = draw(elm_size)
      image.format = image_format
      return image.to_blob
    end

    # QRコード描画
    def draw(elm_size = 4)
      elm_size = 4 if elm_size.zero?
      length = self.modules.size
      width = elm_size * length
      padding = elm_size * 4
      
      image = Magick::Image.new(width + 2 * padding, width + 2 * padding,
                                Magick::HatchFill.new('white'))
      drawer = Magick::Draw.new
      
      drawer.stroke_opacity(0)
      drawer.fill('black')
      
      row_cnt, col_cnt = 0, 0
      self.modules.each() { |col|
        row_cnt = 0
        col.each() { |row|
          if row
            point_tl_x, point_tl_y = padding + row_cnt * elm_size, padding + col_cnt * elm_size
            point_br_x, point_br_y = point_tl_x + elm_size - 1,  point_tl_y + elm_size - 1
            drawer.rectangle point_tl_x, point_tl_y, point_br_x, point_br_y
          end
          row_cnt += 1
        }
        col_cnt += 1
      }
      drawer.draw(image)
      image
    end
  end
end

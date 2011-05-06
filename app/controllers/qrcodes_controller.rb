# QRコード管理
class QrcodesController < ApplicationController

  # QRコード表示
  #
  # ==== 引数
  #
  # * params[:url] - QRコード対象URL
  # * params[:size] - 画像サイズ
  def show
    @qr = RQRCode::QRCode.new(params[:url], :level => :l)
    send_data(@qr.to_qr_binary(params[:size].to_i),
              :filename => 'qrcode.png',
              :type => 'image/png',
              :disposition => 'inline')
  end
end

require 'fileutils'

# 動画ファイルを変換するモジュール
#
# 実装上はコマンドラインを実行する
module Mars::Movie::Converter
  # 変換コマンドのパス
  FFMPEG                = '/usr/bin/ffmpeg'
  # MP4Box コマンドへのパス
  MP4BOX                = '/usr/local/bin/MP4Box'
  # PC 用動画ファイルのサイズ
  PC_SIZE               = {:width => 450, :height => 338}
  # モバイル用動画ファイルのサイズ
  MOBILE_SIZE           = {:width => 176, :height => 144}
  # PC 用サムネイル画像のサイズ
  PC_THUMBNAIL_SIZE     = {:width => 60, :height => 46}
  # モバイル用サムネイル画像のサイズ
  MOBILE_THUMBNAIL_SIZE = {:width => 48, :height => 36}
  # サムネイル画像を撮影する時間
  THUMBNAIL_TIMING      = '00:00:01'
  # 変換ログ保存パス
  CONVERT_LOG_FILE_PAHT = 
    File.expand_path(File.join(File.dirname(__FILE__), '../../..', 'log', 'ffmpeg.log'))
  # コマンド実行結果を捨てる
  if Mars::Movie::ResourceLoader['application']['realtime_convert']
    PIPE_EXPRESSION     = " >> #{CONVERT_LOG_FILE_PAHT} 2>&1"
  else
    PIPE_EXPRESSION     = ''
  end

  # 入力ファイルの形式を修正する
  #
  # 3gpp, 3gpp2 形式のファイルはフラグメントされている可能性があり、正しく変換できないため
  # 事前に ffmpeg が処理できるように加工を施す
  # 拡張子が 3gp , 3g2 でない場合はなにもしない
  def self.fix_container(input_file_path)
    return true unless %w( .3gp .3g2 ).include?(File.extname(input_file_path).downcase)
    temporary_file_path = prefixed('fixed-', input_file_path)
    cmd = "#{MP4BOX} -add #{input_file_path} -new #{temporary_file_path}"
    Rails.logger.debug{ "DEBUG(fix_container) : #{cmd}" }
    unless system(cmd + PIPE_EXPRESSION)
      File.delete(temporary_file_path) if File.exists?(temporary_file_path)
      return false
    end
    File.delete(input_file_path) if File.exists?(input_file_path)
    File.rename(temporary_file_path, input_file_path)
    return true
  end

  # 入力ファイルを .flv ファイルに変換する
  def self.convert_to_flv(input_file_path, output_file_path)
    cmd = "#{FFMPEG} -i #{input_file_path} -y -vcodec flv -s #{PC_SIZE[:width]}x#{PC_SIZE[:height]} -ar 44100 #{output_file_path}"
    Rails.logger.debug{ "DEBUG(convert_to_flv) : #{cmd}" }
    return system(cmd + PIPE_EXPRESSION)
  end

  # 入力ファイルを .3gp ファイルに変換する
  #
  # 変換後のファイルは MP4Box コマンドでヘッダを調整しておく
  def self.convert_to_3gp(input_file_path, output_file_path)
    temporary_file_path = prefixed('fixed-3gp-', output_file_path)
    cmd = "#{FFMPEG} -i #{input_file_path} -y -vcodec mpeg4 -r 8 -vb 32000 -acodec libopencore_amrnb -ac 1 -ar 8000 -ab 12200 -s #{MOBILE_SIZE[:width]}x#{MOBILE_SIZE[:height]} -f 3gp #{temporary_file_path}"
    Rails.logger.debug{ "DEBUG(convert_to_3gp) : #{cmd}" }
    return false unless system(cmd + PIPE_EXPRESSION)
    cmd = "#{MP4BOX} -add #{temporary_file_path} -brand 3gp5:256 #{output_file_path}"
    Rails.logger.debug{ "DEBUG(convert_to_3gp) : #{cmd}" }
    unless system(cmd + PIPE_EXPRESSION)
      File.delete(temporary_file_path) if File.exists?(temporary_file_path)
      return false
    end
    File.delete(temporary_file_path) if File.exists?(temporary_file_path)

    return true
  end

  # 入力ファイルを .3g2 ファイルに変換する
  #
  # 変換後のファイルは MP4Box コマンドでヘッダを調整しておく
  def self.convert_to_3g2(input_file_path, output_file_path)
    temporary_file_path = prefixed('fixed-3g2-', output_file_path)
    cmd = "#{FFMPEG} -i #{input_file_path} -y -vcodec mpeg4 -r 8 -vb 32000 -acodec libopencore_amrnb -ac 1 -ar 8000 -ab 12200 -s #{MOBILE_SIZE[:width]}x#{MOBILE_SIZE[:height]} -f 3g2 #{temporary_file_path}"
    Rails.logger.debug{ "DEBUG(convert_to_3g2) : #{cmd}" }
    return false unless system(cmd + PIPE_EXPRESSION)
    cmd = "#{MP4BOX} -add #{temporary_file_path} -brand kddi -ab 3g2a #{output_file_path}_temp"
    Rails.logger.debug{ "DEBUG(convert_to_3g2) : #{cmd}" }
    unless system(cmd + PIPE_EXPRESSION)
      File.delete(temporary_file_path) if File.exists?(temporary_file_path)
      return false
    end
    cmd = "mv #{output_file_path}_temp #{output_file_path}"
    Rails.logger.debug{ "DEBUG(convert_to_3g2) : #{cmd}" }
    unless system(cmd + PIPE_EXPRESSION)
      File.delete(temporary_file_path) if File.exists?(temporary_file_path)
      return false
    end
    File.delete(temporary_file_path) if File.exists?(temporary_file_path)

    return true
  end

  # PC 用サムネイル画像生成
  #
  # 入力ファイルには flv を使用すること
  # 画像ファイルフォーマットは自動判定
  # * jpg => JPEG 画像
  def self.generate_pc_thumbnail(input_file_path, output_file_path)
    cmd = "#{FFMPEG} -i #{input_file_path} -f image2 -ss #{THUMBNAIL_TIMING} -s #{PC_THUMBNAIL_SIZE[:width]}x#{PC_THUMBNAIL_SIZE[:height]} -vframes 1 #{output_file_path}"
    Rails.logger.debug{ "DEBUG(generate_pc_thumbnail) : #{cmd}" }
    return system(cmd + PIPE_EXPRESSION)
  end

  # モバイル用サムネイル画像生成
  #
  # 入力ファイルには flv を使用すること
  # 画像ファイルフォーマットは自動判定
  # * jpg => JPEG 画像
  def self.generate_mobile_thumbnail(input_file_path, output_file_path)
    cmd = "#{FFMPEG} -i #{input_file_path} -f image2 -ss #{THUMBNAIL_TIMING} -s #{MOBILE_THUMBNAIL_SIZE[:width]}x#{MOBILE_THUMBNAIL_SIZE[:height]} -vframes 1 #{output_file_path}"
    Rails.logger.debug{ "DEBUG(generate_mobile_thumbnail) : #{cmd}" }
    return system(cmd + PIPE_EXPRESSION)
  end

  # ファイル変換に利用する一時ファイル名を生成
  #
  # ディレクトリ名を含むファイル名を指定された prefix をファイル名の前に付与したものを返却
  def self.prefixed(prefix, path)
    File.join(File.dirname(path), prefix + File.basename(path))
  end
end

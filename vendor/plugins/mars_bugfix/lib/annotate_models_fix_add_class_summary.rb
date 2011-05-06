# Copyright 2009 FUJITSU SHIKOKU SYSTEMS LIMITED
# FUJITSU SHIKOKU SYSTEMS CONFIDENTIAL
#
#
module AnnotateModels
  # anotate_modelsで出力した情報の下にコメントを書き込むと次の
  # annotate_modelsの際に正しく出力されなくなる為，それ用のコードを追
  # 加しました．
  def self.annotate_one_file(file_name, info_block)
    if File.exist?(file_name)
      content = File.read(file_name)

      # Remove old schema info
      content.sub!(/^# #{PREFIX}.*?\n(#.*\n)*\n/, '')
      if content.sub!(/^# #{PREFIX}.*?\n(#.*\n)*#\n#\n/, '')
        info_block = info_block.strip + "\n#\n"
      end

      # Write it back
      File.open(file_name, "w") { |f| f.puts info_block + content }
    end
  end
end
